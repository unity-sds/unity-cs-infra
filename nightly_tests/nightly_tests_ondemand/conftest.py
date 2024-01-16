import pytest

@pytest.fixture(scope="session")
def test_results(request):
    request.session.results = []
    yield request.session.results

@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    result = outcome.get_result()
    
    if result.when == 'call':
        test_name = item.name
        status = 'PASSED' if result.passed else 'FAILED'
        item.session.results.append({'name': test_name, 'status': status})

def pytest_sessionfinish(session, exitstatus):
    with open('makereport_output.txt', 'w') as f:
        print_table(session.results, file=f)

def print_table(results, file=None):
    max_name_length = max(len(result['name']) for result in results)
    name_width = max(max_name_length, len('Test Name'))

    print(f"\n{'Test Name'.ljust(name_width)} | {'Status'}", file=file)
    print(f"{'-' * name_width}-+--------", file=file)

    for result in results:
        print(f"{result['name'].ljust(name_width)} | {result['status']}", file=file)

