"""
E2E Test Cases for Authentication & Native Permissions
Covers TC-01 (Google Sign-In), TC-09 (POST_NOTIFICATIONS), TC-10 (Sign-Out)
"""

import pytest

@pytest.mark.asyncio
async def test_tc01_google_signin(artemis):
    """TC-01: Native Google Account Picker and Home Navigation."""
    instruction = (
        "Open TokenScope app. On the login screen, tap 'Tiếp tục với Google'. "
        "In the Google account picker dialog, select the test account. "
        "Verify that Dashboard opens with a personalized greeting 'Xin chào' "
        "and bottom navigation shows 4 tabs."
    )
    result = await artemis.run(instruction)
    assert result.status == "SUCCESS", result.error
    assert result.data.get("verified", False) is True

@pytest.mark.asyncio
async def test_tc09_notification_permission_native(artemis):
    """TC-09: Android 13+ Notification Permission Dialog Handling."""
    instruction = (
        "On first launch on Android 13+, when the system dialog asks "
        "'Cho phép TokenScope gửi thông báo cho bạn?', tap 'Cho phép'. "
        "Verify permission is granted without app crash."
    )
    result = await artemis.run(instruction)
    assert result.status == "SUCCESS", result.error

@pytest.mark.asyncio
async def test_tc10_sign_out(artemis):
    """TC-10: Sign out from Settings tab and verify local session cleared."""
    instruction = (
        "Open TokenScope, signed in. Switch to tab 'Cài đặt'. "
        "Scroll to bottom and tap 'Đăng xuất'. "
        "Verify that LoginScreen is displayed and pressing back does not reopen Dashboard."
    )
    result = await artemis.run(instruction)
    assert result.status == "SUCCESS", result.error
