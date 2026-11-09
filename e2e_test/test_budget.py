"""
E2E Test Cases for Budget Management & In-App Alerts (Flow B & Flow C)
Covers TC-05 (Update Budget), TC-06 (Alerts Center & Notification Deep-link)
"""

import pytest

@pytest.mark.asyncio
async def test_tc05_adjust_monthly_budget(artemis):
    """TC-05: Adjust AI monthly budget and warning threshold."""
    instruction = (
        "On Dashboard, tap the cream 'Cảnh báo ngân sách' card to open BudgetScreen. "
        "Scroll to 'Điều chỉnh ngân sách & ngưỡng cảnh báo'. Enter new limit '50.00' and tap 'Lưu ngân sách'. "
        "Confirm dialog, and verify that new limit $50.00 is reflected on progress bar."
    )
    result = await artemis.run(instruction)
    assert result.status == "SUCCESS", result.error

@pytest.mark.asyncio
async def test_tc06_alerts_center_and_navigation(artemis):
    """TC-06: Open Alerts center and tap notification to navigate."""
    instruction = (
        "On Dashboard, tap the bell notification icon on header. "
        "Verify AlertsScreen opens listing received FCM notifications. "
        "Tap on budget warning notification and verify it navigates directly to BudgetScreen."
    )
    result = await artemis.run(instruction)
    assert result.status == "SUCCESS", result.error
