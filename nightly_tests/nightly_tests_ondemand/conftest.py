import pytest

# Fixture for initializing an empty list to store test results. Scope is set to 'session' to show across all tests in a session.
@pytest.fixture(scope="session")
def test_results(request):
    request.session.results = []
    yield request.session.results

# A hook implementation to intercept test reports. This function records the name and status of each test when it's called.
@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    result = outcome.get_result()
    
    # Record the test name and its pass/fail status after each test is executed.
    if result.when == 'call':
        test_name = item.name
        status = 'PASSED' if result.passed else 'FAILED'
        item.session.results.append({'name': test_name, 'status': status})

# Function executed at the end of the test session. It writes the test results to a file.
def pytest_sessionfinish(session, exitstatus):
    with open('makereport_output.txt', 'w') as f:
        print_table(session.results, file=f)

# Function to print the test results in a table format. The output can be directed to a file.
def print_table(results, file=None):
    # ASCII symbols for pass and fail
    pass_symbol = '✔'
    fail_symbol = '✖'

    # Determine the maximum length of test names to format the table properly.
    max_name_length = max(len(result['name']) for result in results)
    name_width = max(max_name_length, len('Test Name'))

    # Print table headers.
    print(f"\n{'Test Name'.ljust(name_width)} | {'Status'}", file=file)
    print(f"{'-' * name_width}-+--------", file=file)

    # Print each test result in the table with the respective symbol.
    for result in results:
        status_symbol = pass_symbol if result['status'] == 'PASSED' else fail_symbol
        print(f"{result['name'].ljust(name_width)} | {status_symbol}", file=file)

