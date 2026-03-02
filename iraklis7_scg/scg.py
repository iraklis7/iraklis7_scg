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
        timeout = 600.0
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

    async def build_uvm_tb(self, model, streaming, attachments):
        action = "scg_build_uvm_tb"
        timeout = 1800.0
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
            },
            "scg_build_uvm_tb": {
                "user": """You are an experienced design verification 
engineer, tasked with building a UVM testbench for a device 
specification. """,
                "prompt": """You will be provided with a device 
specification document as an attachment. The specification document
should contain all necessary information to produce a functional 
device implementation, as well as build a UVM testbench for the device.

Read the specification to the end before proceeding, as important 
information may be spread across the document. If the specification appears 
incomplete, just return an error message explaining what information
is missing and stop here.

Consider the functionality described in the specification and think about 
how the testbench would verify all aspects of the device specification. If
the device offers different configuration options, consider how the 
testbench would verify all the different configuration permutations. 

Checks: Checks should be implemented to verify the correct functionality 
of the device as described in the specification.  

For example, if the specification states that a data frame has a
parity bit that verifies the integrity of the data payload, then a
check must be implemented to verify the correctness of that parity bit.

All checks should include an error message with a reference to the 
specific section, diagram, table or sentence in the specification that 
best describes that particular functionality.

Coverage: You may disregard coverage completely at this point.

Scoreboard: You may disregard the scoreboard completely at this point.

Sequences and sequence items should be appropriately parameterized 
to allow for easy configuration, reuse, error injections and fully 
exercising the specification functionality. 

Monitor: The monitor passively observes the interface signals and 
extracts the necessary information to be able to check the correct 
functionality of the device.

If the specification defines separate RX/TX paths for the
device, make sure that the monitor is able to monitor each path
independently. The monitor functionality should be complete, e.g.
for a serial communication protocol based on data frames, it should
sample all the bits associated with the data frame, including start
bits, stop bits, and provide for optional features, such as a parity
bit. Checks should also be present to verify the correctness of all
data frame bits.

Phases: Do not use uvm_*_phase, such as uvm_build_phase, uvm_run_phase,
etc, only use uvm_phase.

Objections: Any objections raised by tests at the begining of the 
run_phase() and dropped at the end of the run_phase(). 
Do not raise objections in any other phase, such as build_phase(), 
connect_phase(), etc.

Logging: Appropriate log messages should be included in the 
testbench, with the appropriate log level, to allow for easy 
debugging. Such log messages should include:
uvm_fatal: for unrecoverable errors, such as uninstantiated components
uvm_error: when a functional error occurs, such as a failed check
uvm_warning: for unexpected but non-fatal situations, such as an 
unrecognized configuration option
uvm_info: for general information about the testbench operation, 
such as component instantiation, sequence start and end, etc.
Use uvm_info with UVM_LOW verbosity for events that happen rarely,
such as component instantiation
Use uvm_info UVM_MEDIUM verbosity for events that happen more often, 
such as sequence start and end, data frame transmission, etc.
Use uvm_info with UVM_HIGH verbosity for events that happen very 
frequently, such as the transmission phases of a data frame, etc.
Use uvm_info with UVM_DEBUG verbosity for very detailed information, 
such as the values of individual bits in a data frame etc.

The testbench structure, filenames, classnames, and variables 
should follow the UVM best practices and naming conventions. 
You may refer to a basic UVM testbench at 
https://github.com/antmicro/verilator-uvm-example

Simulation: Only the verilator simulator v5.042 supported at this 
point, so the testbench should be built with this verilator version in mind. 
The testbench should be built in such a way that it can be easily 
simulated with verilator, without the need for any modifications.

Also, only a verilator-specific UVM version IEEE 1800.2-2017 is 
supported at this point, which may be found at 
https://github.com/verilator/uvm

Implementation: All UVM testbench files should be in the same directory, do not create
separate directory for agent, monitor, etc. 
The testbench should be complete and ready to be simulated with 
verilator, without the need for any modifications.

In order to compile the testbench, it is necessary to include the
UVM_HOME directory and the uvm_pkg.sv file in the verilator command.

Do not use "// Verilator" in any file, as this seems to confuse the
verilator. Using "// This is Verilator" seems fine.

The flah -timing also needs to be set for verilator, as the 
testbench relies on the timing information provided.

-Wno-WIDTHTRUNC -Wno-WIDTHEXPAND also need to be included in the
compilation of the testbench, as there are some intentional width 
truncations and expansions.

Delays are not legal in functions, use tasks instead.

As there are some issues with the verilator compilation of the testbench,
do not attempt to compile the testbench within the Makefile, just 
directly build the executable in the Makefile.

It is illegal for functions to call tasks, as tasks consume time.
Do not forget to add a pkg file, which includes all the files in the 
package.
Do not instantiate the DUT at this point, however, fully implement the
monitor and driver functionality using the interface.
Do NOT look at other directories in the @workspace, unless specifically
instructed to do so.
Instead of the -exe flag, use the --binary flag to build the testbench 
executable.
Only use the --trace-vcd flag for verilator, do not use any other 
trace flags
Device specific: Ignore the Wishbone interface for now, and only
focus on the UART interface.

Destination: Do not ask for confirmation, just save the testbench 
files in the @workspace/uvm_tb directory.
""",
            }
        }
