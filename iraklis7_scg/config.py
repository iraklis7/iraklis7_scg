import logging
from pathlib import Path
import sys

from dotenv import load_dotenv

# Load environment variables from .env file if it exists
load_dotenv()

# Setup logger
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)
formatter = logging.Formatter("%(asctime)s | %(levelname)s | %(message)s")

stdout_handler = logging.StreamHandler(sys.stdout)
stdout_handler.setLevel(logging.INFO)
stdout_handler.setFormatter(formatter)
file_handler = logging.FileHandler("iraklis7_scg.log")
file_handler.setLevel(logging.DEBUG)
file_handler.setFormatter(formatter)

logger.addHandler(file_handler)
logger.addHandler(stdout_handler)

# Setup PROJ_ROOT
PROJ_ROOT = Path(__file__).resolve().parents[1]
logger.info(f"PROJ_ROOT path is: {PROJ_ROOT}")

# Setup directories
SPECS_DIR = PROJ_ROOT / "specs"
CURRENT_SPEC = SPECS_DIR / "UART_current.pdf"
LATEST_SPEC = SPECS_DIR / "UART_latest.pdf"
REPORT_DIR = PROJ_ROOT / "reports"
