import asyncio
import pytest
from copilot.types import FileAttachment
import iraklis7_scg.config as config
from iraklis7_scg.scg import SCG


@pytest.mark.asyncio
async def test_scg():
    try:
        # Instantiate the specification generator
        scg = SCG()
        
        # Start the CoPilot client
        await scg.client_start()

        
        # Create a session and send the prompt and specifications
        await scg.create_report(model="gpt-5.2-Codex", 
                    streaming=False, 
                    attachments = [FileAttachment(type="file", path=str(config.LATEST_SPEC)), 
                                    FileAttachment(type="file", path=str(config.CURRENT_SPEC))
                                  ]
                                )
        config.logger.info(f"Specification analysis and report completed")
    except Exception as e:
        config.logger.error(f"Error: {e}")
    finally:
        # Stop the client
        await scg.client_stop()

#asyncio.run(test_scg())