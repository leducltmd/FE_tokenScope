"""
E2E Test Cases for Usage History & Detail Inspection (Flow A)
Covers TC-02 (Search & Filter), TC-03 (Empty Error Path), TC-04 (Detail & cURL)
"""

import pytest

@pytest.mark.asyncio
async def test_tc02_search_and_filter_history(artemis):
    """TC-02: Search API usage records by model name."""
    instruction = (
        "Open TokenScope, signed in. Tap tab 'Lịch sử' on bottom navigation. "
        "In the search bar, type 'gpt-4o'. "
        "Verify that filtered records show gpt-4o badges and result count > 0."
    )
    result = await artemis.run(instruction)
    assert result.status == "SUCCESS", result.error

@pytest.mark.asyncio
async def test_tc03_empty_search_error_path(artemis):
    """TC-03: Error Path - Empty State when search yields no results."""
    instruction = (
        "On Usage History screen, search for non-existent term 'unknown-model-xyz-999'. "
        "Verify that TsEmptyState is shown with message 'Không tìm thấy bản ghi' "
        "and a 'Xóa bộ lọc' button is visible."
    )
    result = await artemis.run(instruction)
    assert result.status == "SUCCESS", result.error

@pytest.mark.asyncio
async def test_tc04_view_usage_detail_and_curl(artemis):
    """TC-04: View Usage Details Screen and inspect Prompt, Response and cURL."""
    instruction = (
        "On Usage History screen, tap on the first record card. "
        "Verify UsageDetailsScreen opens showing 4 metric cards: Model, Tokens, Cost, Latency, "
        "and an expandable cURL code block with copy action."
    )
    result = await artemis.run(instruction)
    assert result.status == "SUCCESS", result.error
