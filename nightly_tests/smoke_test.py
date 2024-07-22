import os
import sys
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
import time

def setup_driver():

    options = Options()
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('window-size=1024x768')
    grid_url = 'http://localhost:4444/wd/hub'

    # Create a Remote WebDriver
    driver = webdriver.Remote(
        command_executor=grid_url,
        options=options
    )

    return driver


def bootstrap_process_status():
    url = os.getenv('MANAGEMENT_CONSOLE_URL')
    driver = setup_driver()
    try:
        driver.get(url)
        time.sleep(40)
        bootstrap_status_element = WebDriverWait(driver, 10).until(
            EC.visibility_of_element_located((By.CSS_SELECTOR, 'h5.text-xl'))
        )
        status_message = bootstrap_status_element.text
        assert "The Bootstrap Process Failed" not in status_message, "Bootstrap process failed"
        return True
    except TimeoutException:
        print("Failed to find the bootstrap status message within the specified time.")
        print("Smoke test failed")
        return False
    except AssertionError as error:
        print("Smoke test failed")
        print(error)
        return False
    finally:
        driver.quit()

if __name__ == "__main__":
    success = bootstrap_process_status()
    sys.exit(0 if success else 1)
