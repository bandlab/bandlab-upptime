import asyncio
from playwright.async_api import async_playwright

async def check_error():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page()

        # Listen for console messages
        page.on('console', lambda msg: print(f'CONSOLE: {msg.text}'))

        # Listen for failed requests
        page.on('requestfailed', lambda request: print(f'FAILED REQUEST: {request.url} - {request.failure}'))

        try:
            await page.goto('https://upptime.bandlab.com/history/bandlab', timeout=30000)
            await page.wait_for_load_state('networkidle')

            # Get the page content
            content = await page.content()
            print('PAGE TITLE:', await page.title())
            print('PAGE CONTENT LENGTH:', len(content))

            # Check for error messages in the DOM
            error_elements = await page.query_selector_all('[class*="error"], [id*="error"]')
            for elem in error_elements:
                text = await elem.inner_text()
                if text:
                    print(f'ERROR ELEMENT: {text[:200]}...')

        except Exception as e:
            print(f'ERROR: {e}')
        finally:
            await browser.close()

asyncio.run(check_error())