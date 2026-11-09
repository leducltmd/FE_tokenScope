"""
E2E Test Cases for Cloud Storage PDF Export & Remote Config Live Changes
Covers TC-07 (PDF Generation & Storage Upload), TC-08 (Remote Config Dynamic Promo Banner)
"""

import pytest

@pytest.mark.asyncio
async def test_tc07_export_pdf_and_upload_storage(artemis):
    """TC-07: Generate real expense PDF and upload to Firebase Cloud Storage."""
    instruction = (
        "Open TokenScope, signed in. Switch to tab 'Cài đặt'. "
        "Locate section 'Báo cáo chi phí' and tap 'Xuất báo cáo PDF'. "
        "Observe realtime progress bar advancing from 0% to 100%. "
        "Verify success SnackBar appears with download link under reports/{uid}/."
    )
    result = await artemis.run(instruction)
    assert result.status == "SUCCESS", result.error

@pytest.mark.asyncio
async def test_tc08_remote_config_live_banner(artemis):
    """TC-08: Fetch & Activate Remote Config and verify UI updates without rebuild."""
    instruction = (
        "On tab 'Cài đặt', tap 'Cập nhật thiết lập' under 'Tùy chỉnh trải nghiệm'. "
        "Switch back to tab 'Tổng quan'. "
        "Verify that purple TsPromoBanner is visible above the budget card with live text."
    )
    result = await artemis.run(instruction)
    assert result.status == "SUCCESS", result.error
