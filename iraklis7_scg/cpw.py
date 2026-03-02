import asyncio
from datetime import datetime

from copilot import CopilotClient, CopilotSession
from copilot.generated.session_events import SessionEventType

import iraklis7_scg.config as config


class CPW(object):
    def __init__(self):
        self.__client = CopilotClient()
        self.__done = asyncio.Event()
        self.__session: CopilotSession
        self.__dict = self.__create_dict()

    def __handler(self, event):
        if event.type == SessionEventType.ASSISTANT_MESSAGE_DELTA:
            # Incremental text chunk
            print(event.data.delta_content, end="", flush=True)
            # config.logger.info(event.data.delta_content)
        elif event.type == SessionEventType.ASSISTANT_REASONING_DELTA:
            # Incremental reasoning chunk (model-dependent)
            print(event.data.delta_content, end="", flush=True)
            # config.logger.info(event.data.delta_content)
        else:
            if event.type == SessionEventType.ASSISTANT_MESSAGE:
                # Final complete message
                if event.data.content != "":
                    config.logger.info(event.data.content)
            elif event.type == SessionEventType.ASSISTANT_REASONING:
                # Final reasoning content
                config.logger.debug("--- Reasoning ---")
                config.logger.debug(event.data.content)
            elif event.type == SessionEventType.SESSION_USAGE_INFO:
                config.logger.debug(f"Current tokens: \
                                    {event.data.current_tokens}")
            elif event.type == SessionEventType.TOOL_EXECUTION_START:
                config.logger.debug(
                    f"Tool name: {event.data.tool_name} with id={event.data.tool_call_id}"
                )
            elif event.type == SessionEventType.TOOL_EXECUTION_COMPLETE:
                if event.data.result:
                    config.logger.debug(f"Content: {event.data.result.content}")
                    config.logger.debug(f"Detailed Content: {event.data.result.detailed_content}")
                if event.data.error:
                    config.logger.debug(f"Message: {event.data.error.message}")
                config.logger.debug(f"Success: {event.data.success}")
            elif event.type == SessionEventType.ASSISTANT_USAGE:
                config.logger.debug(f"Cache Read Tokens: {event.data.cache_read_tokens}")
                config.logger.debug(f"Cache Write Tokens: {event.data.cache_write_tokens}")
                config.logger.debug(f"Cost: {event.data.cost}")
                config.logger.debug(f"Duration: {event.data.duration}")
                config.logger.debug(f"Input Tokens: {event.data.input_tokens}")
                config.logger.debug(f"Output Tokens: {event.data.output_tokens}")
            elif event.type == SessionEventType.SESSION_ERROR:
                config.logger.error(f"Error: {event.data.message}")
                raise Exception(f"Session Error: {event.data.message}")
            elif event.type == SessionEventType.SESSION_IDLE:
                self.__done.set()
            else:
                config.logger.debug(f"Unhandled event type: {event.type}")

    # Create client
    # XXX async with CopilotClient() as client:
    # This statement from the copilot SDK exampels produces the following error
    # copilot.client.CopilotClient' object does not support the asynchronous
    # context manager protocol (missed __aexit__ method)
    async def client_start(self):
        try:
            # Start client and ping to check connectivity
            await self.__client.start()
            config.logger.info("Client started")
        except Exception as e:
            config.logger.error(f"Error: {e}")
            raise

    async def client_list_models(self):
        try:
            reply = await self.__client.list_models()
            config.logger.debug(f"List models:\n{reply}")
            return reply
        except Exception as e:
            config.logger.error(f"Error: {e}")
            raise

    async def client_ping(self):
        try:
            response = await self.__client.ping("health check")
            test = response.timestamp / 1000.0
            formatted = datetime.fromtimestamp(test).strftime("%F %T.%f")[:-3]
            config.logger.info(f"Server responded at {formatted}")
        except Exception as e:
            config.logger.error(f"Error pinging server: {e}")
            raise

    async def client_check_connection(self):
        try:
            result = self.__client.get_state()
            config.logger.info(f"Client state is {result}")
            return result
        except Exception as e:
            config.logger.error(f"Error: {e}")
            raise

    async def create_session(self, config):
        # Same problem as above
        # async with await client.create_session({"model": model}) as session:
        try:
            self.__session = await self.__client.create_session(config)
            self.__session.on(self.__handler)
        except Exception as e:
            config.logger.error(f"Error: {e}")
            raise

    async def client_send(self, streaming, options, timeout):  # -> Optional[SessionEvent]:
        # Create a session and send the prompt and specifications
        try:
            if streaming:
                result = await self.__session.send(options)
                await self.__done.wait()
            else:
                response = await self.__session.send_and_wait(options, timeout=timeout)
                if response:
                    return response.data.content
        except Exception as e:
            config.logger.error(f"Error: {e}")
            raise

    async def session_destroy(self):
        try:
            config.logger.debug("Destroying session...")
            await self.__session.destroy()
        except Exception as e:
            config.logger.error(f"Error: {e}")
            raise

    async def client_stop(self):
        try:
            config.logger.debug("Stopping client...")
            await self.__client.stop()
        except Exception as e:
            config.logger.error(f"Error: {e}")
            raise

    def get_session(self):
        return self.__session

    def get_client(self):
        return self.__client

    def get_params(self, dkey) -> dict:
        return self.__dict[dkey]

    def get_user_message(self, dkey) -> str:
        return self.__dict[dkey]["user"]

    def get_prompt(self, dkey) -> str:
        return self.__dict[dkey]["prompt"]

    def __create_dict(self) -> dict:
        return {}
