import os
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
    driver = webdriver.Chrome(options=options)
    return driver

def uninstall_aws_resources():
    # Use os.getenv to retrieve the URL from an environment variable
    url = os.getenv('MANAGEMENT_CONSOLE_URL')
    if not url:
        print("MANAGEMENT_CONSOLE_URL environment variable is not set.")
        return

    driver = setup_driver()
    try:
        driver.get(url)
        time.sleep(2)  # Wait for the page to load

        # Locate and click the Uninstall link
        uninstall_link = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, "a.inline-flex.items-center.bg-white"))
        )
        uninstall_link.click()

        # Explicitly wait for 10 seconds
        time.sleep(10)

        # Locate and click
        go_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, "//button[text()='Go!']"))
        )
        go_button.click()

        print("Uninstall process initiated successfully.")

    except TimeoutException:
        print("Failed to perform uninstall - either elements were not clickable or not found as expected.")
    finally:
        driver.quit()

if __name__ == "__main__":
    uninstall_aws_resources()

