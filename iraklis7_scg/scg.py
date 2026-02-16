from copilot import SessionConfig
from copilot.types import MessageOptions, SessionConfig, SystemMessageAppendConfig

import iraklis7_scg.config as config
from iraklis7_scg.cpw import CPW


class SCG(CPW):
    def __init__(self):
        super().__init__()
        self.__dict = self.__create_dict()

    async def create_report(self, model, streaming, attachments):
        action = "scg_delta_report"
        timeout = 300.0
        user = self.get_user_message(action)
        prompt = self.get_prompt(action)
        sys_mes = SystemMessageAppendConfig(mode="append", content=user)
        try:
            await self.create_session(
                SessionConfig(model=model, system_message=sys_mes, streaming=streaming)
            )

            response = await self.client_send(
                streaming,
                MessageOptions(prompt=prompt, attachments=attachments, mode="immediate"),
                timeout,
            )
        except Exception as e:
            config.logger.error(f"Error: {e}")
            raise
        finally:
            # Destroy the session
            await self.session_destroy()

    def get_params(self, dkey) -> dict:
        return self.__dict[dkey]

    def get_user_message(self, dkey) -> str:
        return self.__dict[dkey]["user"]

    def get_prompt(self, dkey) -> str:
        return self.__dict[dkey]["prompt"]

    def __create_dict(self) -> dict:
        return {
            "scg_delta_report": {
                "user": """You are an experienced design verication technical lead, tasked with identifying and analyzing the differences between the latest device specification and its previous version. """,
                "prompt": """You will be provided with both versions of the specification as attachments. Make sure that both files refer to the same specification and check that the version number on one is higher than the other. The version number may be found in the filename or inside the document, usually the first page. If you are unable to find the version numbers or if one of the files does not refer to the same specification, just return an error message explaining the situation and stop here. Otherwise, continue to the next part.
A specification document must contain all the required information to produce a functional device that complies to the particular specification version. Make no assumptions about similar specifications, older specifications and disregard typical usage assumptions, only focus on the contents of the specifications provided. If a revision history is provided, disregard it and focus only on the contents of the specifications provided. Read both specifications to the end before proceeding, as important information may be spread across each document.
Look for differences in:
- architecture block diagrams
- interface signals and connections
- timing information
- power information
- clock rates
- reset behavior
- register definitions, contents and operation
- inintialization sequences

Once you are confident that you have identified all functional changes, produce a report with the following structure:

1. Specification Overview: Mention the latest specification name and version, along with a brief summary of its features and operation.
2. New Features: List all new features in the latest specification in separate sections. For each new feature, provide a brief description of the functionality introduced with this feature, as well as references to specific specification subsections, diagrams, tables and sentences that most accurately describe its functionality and operation. Also, provide a brief description of the impact of this feature on the complexity of the latest specification and a rating of expected development effort as either 'Minor' or 'Major'.
3. Conclusion: Provide a detailed estimate on the complexity of the latest specification vs the previous veraion, taking into account the new features mentioned above. Also, estimate how this complexity will weigh on the development of the device implementation (rtl) and UVM verification environment.

Review the report and make sure that all new features contain proper references that will allow quick and easy identification on the specification document. When done, save the report as <SPECIFICATION NAME>_<latest version>_delta_<previous version>_report.md in the @workspace/reports directory.""",
            }
        }
