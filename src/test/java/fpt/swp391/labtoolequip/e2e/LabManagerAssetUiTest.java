package fpt.swp391.labtoolequip.e2e;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.microsoft.playwright.Browser;
import com.microsoft.playwright.BrowserType;
import com.microsoft.playwright.Locator;
import com.microsoft.playwright.Page;
import com.microsoft.playwright.Playwright;
import com.microsoft.playwright.options.FilePayload;
import com.microsoft.playwright.options.SelectOption;
import java.io.ByteArrayOutputStream;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;

@EnabledIfSystemProperty(named = "e2e.enabled", matches = "true")
class LabManagerAssetUiTest {
	private static final String BASE_URL = System.getProperty("e2e.baseUrl", "http://localhost:8080");
	private static final String EMAIL = System.getProperty("e2e.email", "manager@gmail.com");
	private static final String PASSWORD = System.getProperty("e2e.password", "123");

	@Test
	void labManagerCanFilterAssetsByStatusAndCondition() {
		try (Playwright playwright = Playwright.create();
				Browser browser = launch(playwright);
				Page page = login(browser)) {
			page.navigate(BASE_URL + "/lab-manager/assets");
			page.locator("select[name='status']").selectOption("AVAILABLE");
			page.locator("select[name='condition']").selectOption("GOOD");
			page.locator("form.filter-bar button[type='submit']").click();

			assertTrue(page.url().contains("status=AVAILABLE"));
			assertTrue(page.url().contains("condition=GOOD"));
			assertTrue(page.getByText("Danh sách sản phẩm").isVisible());
		}
	}

	@Test
	void assetCreateFormRendersRowsForQuantityBoundaryValues() {
		try (Playwright playwright = Playwright.create();
				Browser browser = launch(playwright);
				Page page = login(browser)) {
			page.navigate(BASE_URL + "/lab-manager/assets/new");

			page.locator("#quantity").fill("2");
			assertEquals(2, page.locator("input[name='itemSerialNumber']").count());

			page.locator("#quantity").fill("0");
			assertEquals(1, page.locator("input[name='itemSerialNumber']").count());

			page.locator("#quantity").fill("101");
			assertEquals(100, page.locator("input[name='itemSerialNumber']").count());
		}
	}

	@Test
	void labManagerCanImportTwoItemsFromExcelBeforeCreatingAsset() throws Exception {
		try (Playwright playwright = Playwright.create();
				Browser browser = launch(playwright);
				Page page = login(browser)) {
			page.navigate(BASE_URL + "/lab-manager/assets/new");
			page.locator("#assetFile").setInputFiles(new FilePayload("asset-items.xlsx",
					"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", validImportFile()));
			page.locator("button[name='action'][value='import']").click();

			assertTrue(
					page.getByText("Đã nạp 2 sản phẩm từ Excel. Kiểm tra thông tin rồi bấm Tạo sản phẩm.").isVisible());
			assertEquals(2, page.locator("input[name='itemSerialNumber']").count());
			assertEquals("E2E-IMPORT-01", page.locator("input[name='itemSerialNumber']").nth(0).inputValue());
		}
	}

	@Test
	void labManagerCanCreateAndUpdateAssetItemLifecycle() {
		String assetCode = "E2E-AST-" + System.currentTimeMillis();
		try (Playwright playwright = Playwright.create();
				Browser browser = launch(playwright);
				Page page = login(browser)) {
			createBorrowableAsset(page, assetCode);
			assertTrue(page.getByText("Đã tạo thiết bị và sinh mã riêng cho từng sản phẩm.").isVisible());
			filterByAssetCode(page, assetCode);
			assertEquals(2, assetRows(page, assetCode).count());

			assetRows(page, assetCode).first().locator("a[href$='/edit']").click();
			page.locator("#condition").selectOption("DAMAGED");
			page.locator("#status").selectOption("MAINTENANCE");
			page.locator("button[type='submit']").click();
			assertTrue(page.getByText("Đã cập nhật thông tin sản phẩm.").isVisible());

			page.navigate(BASE_URL + "/lab-manager/assets");
			filterByAssetCode(page, assetCode);
			assetRows(page, assetCode).nth(1).locator("a[href$='/edit']").click();
			page.locator("#condition").selectOption("DAMAGED");
			page.locator("#status").selectOption("AVAILABLE");
			page.locator("button[type='submit']").click();

			assertTrue(page.locator(".error-message").innerText().contains("Sản phẩm hư hỏng nặng"));
		}
	}

	private Browser launch(Playwright playwright) {
		return playwright.chromium()
				.launch(new BrowserType.LaunchOptions().setHeadless(Boolean.getBoolean("e2e.headless")).setSlowMo(150));
	}

	private Page login(Browser browser) {
		Page page = browser.newPage();
		page.navigate(BASE_URL + "/login");
		page.locator("#email").fill(EMAIL);
		page.locator("#password").fill(PASSWORD);
		page.locator("button.login-submit").click();
		page.waitForURL("**/lab-manager/**");
		return page;
	}

	private void createBorrowableAsset(Page page, String assetCode) {
		page.navigate(BASE_URL + "/lab-manager/assets/new");
		page.locator("#assetCode").fill(assetCode);
		page.locator("#assetName").fill("Thiết bị kiểm thử Playwright");
		page.locator("#categoryId").selectOption(new SelectOption().setIndex(1));
		page.locator("#assetType").selectOption("BORROWABLE");
		page.locator("#quantity").fill("2");
		page.locator("input[name='itemSerialNumber']").nth(0).fill(assetCode + "-01");
		page.locator("input[name='itemSerialNumber']").nth(1).fill(assetCode + "-02");
		page.locator("button[name='action'][value='create']").click();
	}

	private void filterByAssetCode(Page page, String assetCode) {
		page.locator("input[name='keyword']").fill(assetCode);
		page.locator("form.filter-bar button[type='submit']").click();
	}

	private Locator assetRows(Page page, String assetCode) {
		return page.locator("tbody tr").filter(new Locator.FilterOptions().setHasText(assetCode));
	}

	private byte[] validImportFile() throws Exception {
		try (XSSFWorkbook workbook = new XSSFWorkbook(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
			XSSFSheet sheet = workbook.createSheet("Asset Items");
			sheet.createRow(0).createCell(0).setCellValue("Serial");
			writeImportRow(sheet, 1, "E2E-IMPORT-01", "Tốt", "Sẵn sàng");
			writeImportRow(sheet, 2, "E2E-IMPORT-02", "Hư hỏng", "Đang bảo trì");
			workbook.write(output);
			return output.toByteArray();
		}
	}

	private void writeImportRow(XSSFSheet sheet, int rowIndex, String serial, String condition, String status) {
		var row = sheet.createRow(rowIndex);
		row.createCell(0).setCellValue(serial);
		row.createCell(2).setCellValue(condition);
		row.createCell(3).setCellValue(status);
	}
}
