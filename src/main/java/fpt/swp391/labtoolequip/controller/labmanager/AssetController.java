package fpt.swp391.labtoolequip.controller.labmanager;

import fpt.swp391.labtoolequip.dao.AssetItemDAO;
import fpt.swp391.labtoolequip.common.AssetItemExcelReader;
import fpt.swp391.labtoolequip.model.AssetItem;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

@WebServlet(urlPatterns = {"/lab-manager/assets/*", "/mentor/assets/*"})
@MultipartConfig(maxFileSize = 5 * 1024 * 1024, maxRequestSize = 6 * 1024 * 1024)
public class AssetController extends HttpServlet {
	private final AssetItemDAO dao = new AssetItemDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			setRoleContext(request);
			String path = request.getPathInfo();
			if ("/new/template".equals(path)) {
				downloadTemplate(response);
				return;
			}
			if ("/new".equals(path)) {
				prepareForm(request);
				forward(request, response, "form.jsp");
				return;
			}
			if (path != null && path.matches("/\\d+/edit")) {
				showItem(request, response, Long.parseLong(path.substring(1, path.indexOf("/edit"))), true);
				return;
			}
			if (path != null && path.matches("/\\d+")) {
				showItem(request, response, Long.parseLong(path.substring(1)),
						Boolean.TRUE.equals(request.getAttribute("editMode")));
				return;
			}
			if (path != null && !path.equals("/") && !path.isBlank()) {
				response.sendError(HttpServletResponse.SC_NOT_FOUND);
				return;
			}
			showList(request, response);
		} catch (SQLException exception) {
			throw new ServletException(exception);
		}
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		String path = request.getPathInfo();
		try {
			setRoleContext(request);
			if (path != null && path.matches("/\\d+/delete")) {
				if (!validCsrf(request)) {
					response.sendError(HttpServletResponse.SC_FORBIDDEN, "Mã bảo vệ CSRF không hợp lệ.");
					return;
				}
				dao.deleteItem(Long.parseLong(path.substring(1, path.indexOf("/delete"))));
				response.sendRedirect(request.getAttribute("assetBasePath") + "?deleted=1");
				return;
			}
			if ("/new".equals(path)) {
				if ("import".equals(request.getParameter("action"))) {
					importItems(request, response);
					return;
				}
				int quantity = parseQuantity(request.getParameter("quantity"));
				dao.createBundle(request.getParameter("assetCode"), request.getParameter("assetName"),
						Long.parseLong(request.getParameter("categoryId")),
						parseBorrowable(request.getParameter("assetType")), request.getParameter("description"),
						readItems(request, quantity));
				response.sendRedirect(request.getAttribute("assetBasePath") + "?created=1");
				return;
			}
			if (path != null && path.matches("/\\d+")) {
				long id = Long.parseLong(path.substring(1));
				AssetItem item = readItem(request, id);
				dao.updateItem(item);
				response.sendRedirect(request.getAttribute("assetBasePath") + "/" + id + "?updated=1");
				return;
			}
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (IllegalArgumentException exception) {
			request.setAttribute("message", exception.getMessage());
			if ("/new".equals(path)) {
				try {
					prepareForm(request);
				} catch (SQLException sqlException) {
					throw new ServletException(sqlException);
				}
				request.getRequestDispatcher("/WEB-INF/views/labmanager/assets/form.jsp").forward(request, response);
			} else if (path != null && path.matches("/\\d+")) {
				request.setAttribute("editMode", true);
				doGet(request, response);
			} else if (path != null && path.matches("/\\d+/delete")) {
				try {
					showList(request, response);
				} catch (SQLException sqlException) {
					throw new ServletException(sqlException);
				}
			} else {
				response.sendError(HttpServletResponse.SC_BAD_REQUEST);
			}
		}
	}

	private void showList(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		request.setAttribute("assetItems", dao.findAll(request.getParameter("keyword"), request.getParameter("status"),
				request.getParameter("condition")));
		request.setAttribute("csrfToken", csrfToken(request));
		forward(request, response, "list.jsp");
	}

	private void showItem(HttpServletRequest request, HttpServletResponse response, long id, boolean editMode)
			throws SQLException, ServletException, IOException {
		AssetItem item = dao.findById(id).orElse(null);
		if (item == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		request.setAttribute("item", item);
		request.setAttribute("editMode", editMode);
		request.setAttribute("csrfToken", csrfToken(request));
		forward(request, response, "detail.jsp");
	}

	private void importItems(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException, SQLException {
		try {
			AssetItemExcelReader.ImportData imported = AssetItemExcelReader.read(request.getPart("assetFile"));
			if (imported.items().isEmpty()) {
				throw new IOException("Vui lòng chọn một file Excel có dữ liệu sản phẩm.");
			}
			request.setAttribute("importedItems", imported.items());
			request.setAttribute("quantity", imported.items().size());
			request.setAttribute("message", "Đã nạp " + imported.items().size()
					+ " sản phẩm từ Excel. Kiểm tra thông tin rồi bấm Tạo sản phẩm.");
		} catch (IOException exception) {
			request.setAttribute("message", exception.getMessage());
		}
		prepareForm(request);
		request.getRequestDispatcher("/WEB-INF/views/labmanager/assets/form.jsp").forward(request, response);
	}

	private void downloadTemplate(HttpServletResponse response) throws IOException {
		response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
		response.setHeader("Content-Disposition", "attachment; filename=asset-items-template.xlsx");
		try (Workbook workbook = new XSSFWorkbook()) {
			Sheet sheet = workbook.createSheet("Asset Items");
			Row header = sheet.createRow(0);
			header.createCell(0).setCellValue("Serial");
			header.createCell(1).setCellValue("Image Path");
			header.createCell(2).setCellValue("Condition");
			header.createCell(3).setCellValue("Status");
			header.createCell(4).setCellValue("Purchase Date");
			header.createCell(5).setCellValue("Warranty Until");
			header.createCell(6).setCellValue("Note");
			workbook.write(response.getOutputStream());
		}
	}

	private void prepareForm(HttpServletRequest request) throws SQLException {
		request.setAttribute("categories", dao.findCategories());
		if (request.getAttribute("quantity") == null)
			request.setAttribute("quantity", 1);
	}

	private void setRoleContext(HttpServletRequest request) {
		boolean mentor = request.getServletPath().startsWith("/mentor/");
		request.setAttribute("assetRole", mentor ? "mentor" : "lab-manager");
		request.setAttribute("assetBasePath",
				request.getContextPath() + (mentor ? "/mentor/assets" : "/lab-manager/assets"));
	}

	private String csrfToken(HttpServletRequest request) {
		String token = (String) request.getSession().getAttribute("csrfToken");
		if (token == null) {
			token = java.util.UUID.randomUUID().toString();
			request.getSession().setAttribute("csrfToken", token);
		}
		return token;
	}

	private boolean validCsrf(HttpServletRequest request) {
		String expected = (String) request.getSession().getAttribute("csrfToken");
		return expected != null && expected.equals(request.getParameter("csrfToken"));
	}

	private int parseQuantity(String raw) {
		try {
			int quantity = Integer.parseInt(raw == null ? "1" : raw);
			if (quantity < 1 || quantity > 100)
				throw new IllegalArgumentException("Số lượng phải từ 1 đến 100 sản phẩm.");
			return quantity;
		} catch (NumberFormatException exception) {
			throw new IllegalArgumentException("Số lượng không hợp lệ.");
		}
	}

	private boolean parseBorrowable(String value) {
		if ("BORROWABLE".equals(value))
			return true;
		if ("FIXED".equals(value))
			return false;
		throw new IllegalArgumentException("Vui lòng chọn dạng tài sản.");
	}

	private List<AssetItem> readItems(HttpServletRequest request, int quantity) {
		String[] serials = request.getParameterValues("itemSerialNumber");
		String[] images = request.getParameterValues("itemImagePath");
		String[] conditions = request.getParameterValues("itemCondition");
		String[] statuses = request.getParameterValues("itemStatus");
		String[] purchases = request.getParameterValues("itemPurchaseDate");
		String[] warranties = request.getParameterValues("itemWarrantyUntil");
		String[] notes = request.getParameterValues("itemNote");
		List<AssetItem> items = new ArrayList<>();
		for (int index = 0; index < quantity; index++) {
			AssetItem item = new AssetItem();
			item.setSerialNumber(value(serials, index));
			item.setImagePath(value(images, index));
			item.setCondition(defaultValue(value(conditions, index), "GOOD"));
			item.setStatus(defaultValue(value(statuses, index), "AVAILABLE"));
			item.setPurchaseDate(parseDate(value(purchases, index), "Ngày mua"));
			item.setWarrantyUntil(parseDate(value(warranties, index), "Ngày hết hạn bảo hành"));
			item.setNote(value(notes, index));
			items.add(item);
		}
		return items;
	}

	private AssetItem readItem(HttpServletRequest request, long id) {
		AssetItem item = new AssetItem();
		item.setAssetItemId(id);
		item.setSerialNumber(request.getParameter("serialNumber"));
		item.setImagePath(request.getParameter("imagePath"));
		item.setCondition(defaultValue(request.getParameter("condition"), "GOOD"));
		item.setStatus(defaultValue(request.getParameter("status"), "AVAILABLE"));
		item.setPurchaseDate(parseDate(request.getParameter("purchaseDate"), "Ngày mua"));
		item.setWarrantyUntil(parseDate(request.getParameter("warrantyUntil"), "Ngày hết hạn bảo hành"));
		item.setNote(request.getParameter("note"));
		return item;
	}

	private String value(String[] values, int index) {
		return values != null && index < values.length ? values[index] : null;
	}

	private String defaultValue(String value, String fallback) {
		return value == null || value.isBlank() ? fallback : value.trim();
	}

	private LocalDate parseDate(String value, String label) {
		if (value == null || value.isBlank())
			return null;
		try {
			return LocalDate.parse(value);
		} catch (DateTimeParseException exception) {
			throw new IllegalArgumentException(label + " không hợp lệ.");
		}
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.getRequestDispatcher("/WEB-INF/views/labmanager/assets/" + view).forward(request, response);
	}
}
