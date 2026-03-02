import asyncio
import pytest
from copilot.types import FileAttachment
import iraklis7_scg.config as config
from iraklis7_scg.scg import SCG


@pytest.mark.asyncio
async def test_scg_build():
    try:
        # Instantiate the specification generator
        scg = SCG()
        
        # Start the CoPilot client
        await scg.client_start()

        # Create a session and send the prompt and specifications
        await scg.build_uvm_tb(model="claude-sonnet-4.6", 
                    streaming=True, 
                    attachments = [FileAttachment(type="file", path=str(config.LATEST_SPEC))
                                  ]
                                )
        config.logger.info(f"UVM testbench generation completed")
    except Exception as e:
        config.logger.error(f"Error: {e}")
    finally:
        # Stop the client
        await scg.client_stop()

asyncio.run(test_scg_build())