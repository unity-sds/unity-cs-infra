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
    grid_url = 'http://localhost:4444/wd/hub'

    # Create a Remote WebDriver
    driver = webdriver.Remote(
        command_executor=grid_url,
        options=options
    )

    return driver

screenshot_counter=0
IMAGE_DIR= 'test'
def save_screenshot(driver, description):
    """
    Save a screenshot with a given description, adding a global counter prefix.
    """
    global screenshot_counter
    screenshot_name = f'{screenshot_counter:02d}_{description}.png'  # Format with leading zeros
    screenshot_path = os.path.join(IMAGE_DIR, screenshot_name)
    driver.save_screenshot(screenshot_path)
    screenshot_counter += 1  # Increment the counter


        # Create directory for images if it doesn't exist
    if not os.path.exists(IMAGE_DIR):
        os.makedirs(IMAGE_DIR)

    return screenshot_path

def uninstall_aws_resources():
    url = os.getenv('MANAGEMENT_CONSOLE_URL')

    if not url:
        print("MANAGEMENT_CONSOLE_URL environment variable is not set.")
        return

    driver = setup_driver()
    try:
        driver.get(url)
        time.sleep(2)  # Wait for the page to load

        # Locate the Uninstall link using XPath and click it
        uninstall_link = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, "//a[contains(@class, 'inline-flex') and contains(text(), 'Uninstall')]"))
        )
        driver.execute_script("arguments[0].click();", uninstall_link)

        # Wait for any dynamic content, modals, etc., to finish loading
        time.sleep(2)  # Adjust this delay as necessary

        # Attempt to locate the "Go!" button
        go_button = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, "//button[contains(text(), 'Go!')]"))
        )

        # Use JavaScript to click the "Go!" button
        driver.execute_script("arguments[0].click();", go_button)

        print("Uninstall process initiated successfully.")

    except TimeoutException:
        print("Failed to perform uninstall - either elements were not clickable or not found as expected.")
    finally:
        driver.quit()





if __name__ == "__main__":
    uninstall_aws_resources()

