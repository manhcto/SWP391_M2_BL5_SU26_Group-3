package fpt.swp391.labtoolequip.controller;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.dao.InspectionDAO;
import fpt.swp391.labtoolequip.model.AssetItem;
import fpt.swp391.labtoolequip.model.InspectionItem;
import fpt.swp391.labtoolequip.model.InspectionRecord;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

public abstract class InspectionControllerSupport extends HttpServlet {
	private final InspectionDAO dao = new InspectionDAO();

	protected abstract String roleBase();

	protected abstract String roleName();

	protected boolean canMutate() {
		return true;
	}

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			String path = request.getPathInfo();
			if (path == null || "/".equals(path)) {
				showList(request, response);
				return;
			}
			if ("/new".equals(path)) {
				if (!canMutate()) {
					response.sendError(HttpServletResponse.SC_FORBIDDEN);
					return;
				}
				showForm(request, response, new InspectionRecord(), List.of());
				return;
			}
			if (path.matches("/\\d+/edit")) {
				if (!canMutate()) {
					response.sendError(HttpServletResponse.SC_FORBIDDEN);
					return;
				}
				long id = idFrom(path);
				InspectionRecord inspection = dao.findById(id).orElseThrow();
				if (!"DRAFT".equals(inspection.getStatus())) {
					response.sendError(HttpServletResponse.SC_FORBIDDEN);
					return;
				}
				showForm(request, response, inspection, dao.findItems(id));
				return;
			}
			if (path.matches("/\\d+")) {
				long id = idFrom(path);
				request.setAttribute("inspection", dao.findById(id).orElseThrow());
				request.setAttribute("items", dao.findItems(id));
				forward(request, response, "detail.jsp");
				return;
			}
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (RuntimeException exception) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
		}
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		if (!canMutate()) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		request.setCharacterEncoding("UTF-8");
		String action = request.getParameter("action");
		boolean complete = "complete".equals(action);
		try {
			if (!"draft".equals(action) && !complete) {
				response.sendError(HttpServletResponse.SC_BAD_REQUEST);
				return;
			}
			InspectionRecord record = recordFrom(request);
			List<InspectionItem> items = itemsFrom(request, record.getScope());
			String idValue = request.getParameter("inspectionId");
			long id;
			if (idValue == null || idValue.isBlank()) {
				id = dao.create(AuthSession.userId(request), record, items, complete);
			} else {
				id = Long.parseLong(idValue);
				dao.updateDraft(id, record, items, complete);
			}
			response.sendRedirect(request.getContextPath() + roleBase() + "/inspections/" + id);
		} catch (SQLException exception) {
			throw new ServletException(exception);
		} catch (IllegalArgumentException | IllegalStateException exception) {
			request.setAttribute("message", exception.getMessage());
			try {
				showForm(request, response, recordFrom(request), itemsFromLenient(request));
			} catch (SQLException nested) {
				throw new ServletException(nested);
			}
		}
	}

	private void showList(HttpServletRequest request, HttpServletResponse response)
			throws SQLException, ServletException, IOException {
		request.setAttribute("semesters", dao.findSemesters());
		request.setAttribute("selectedSemesterId", request.getParameter("semesterId"));
		request.setAttribute("selectedType", request.getParameter("type"));
		request.setAttribute("selectedStatus", request.getParameter("status"));
		request.setAttribute("selectedResult", request.getParameter("result"));
		request.setAttribute("fromDate", request.getParameter("fromDate"));
		request.setAttribute("toDate", request.getParameter("toDate"));
		request.setAttribute("inspections",
				dao.findAll(request.getParameter("semesterId"), request.getParameter("type"),
						request.getParameter("status"), request.getParameter("result"),
						request.getParameter("fromDate"), request.getParameter("toDate")));
		forward(request, response, "list.jsp");
	}

	private void showForm(HttpServletRequest request, HttpServletResponse response, InspectionRecord inspection,
			List<InspectionItem> items) throws SQLException, ServletException, IOException {
		List<AssetItem> assetItems = dao.findInspectableItems();
		Map<Long, InspectionItem> inspectionByAssetItem = items.stream().filter(item -> item.getAssetItemId() != null)
				.collect(Collectors.toMap(InspectionItem::getAssetItemId, item -> item, (first, second) -> first));
		request.setAttribute("inspection", inspection);
		request.setAttribute("items", items);
		request.setAttribute("inspectionByAssetItem", inspectionByAssetItem);
		request.setAttribute("assetItems", assetItems);
		request.setAttribute("semesters", dao.findSemesters());
		forward(request, response, "form.jsp");
	}

	private InspectionRecord recordFrom(HttpServletRequest request) {
		InspectionRecord record = new InspectionRecord();
		String id = request.getParameter("inspectionId");
		if (id != null && !id.isBlank()) {
			record.setInspectionId(Long.parseLong(id));
		}
		record.setSemesterId(Long.parseLong(request.getParameter("semesterId")));
		record.setInspectionType(request.getParameter("inspectionType"));
		record.setScope(request.getParameter("scope"));
		record.setInspectionDate(LocalDateTime.parse(request.getParameter("inspectionDate")));
		record.setNote(request.getParameter("note"));
		return record;
	}

	private List<InspectionItem> itemsFrom(HttpServletRequest request, String scope) {
		Set<Long> selected = selectedAssetItems(request, scope);
		List<InspectionItem> items = new ArrayList<>();
		for (Long assetItemId : selected) {
			items.add(itemFrom(request, assetItemId));
		}
		return items;
	}

	private List<InspectionItem> itemsFromLenient(HttpServletRequest request) {
		try {
			return itemsFrom(request, request.getParameter("scope"));
		} catch (RuntimeException exception) {
			return List.of();
		}
	}

	private Set<Long> selectedAssetItems(HttpServletRequest request, String scope) {
		String parameter = "WHOLE_LAB".equals(scope) ? "assetItemId" : "selectedAssetItemId";
		String[] values = request.getParameterValues(parameter);
		if (values == null) {
			return Set.of();
		}
		return java.util.Arrays.stream(values).filter(value -> value != null && !value.isBlank()).map(Long::parseLong)
				.collect(Collectors.toCollection(java.util.LinkedHashSet::new));
	}

	private InspectionItem itemFrom(HttpServletRequest request, Long assetItemId) {
		InspectionItem item = new InspectionItem();
		item.setAssetItemId(assetItemId);
		item.setAssetId(Long.parseLong(value(request, "assetId", assetItemId)));
		item.setExpectedQuantity(intValue(request, "expectedQuantity", assetItemId));
		item.setActualQuantity(intValue(request, "actualQuantity", assetItemId));
		item.setExpectedCondition(value(request, "expectedCondition", assetItemId));
		item.setActualCondition(value(request, "actualCondition", assetItemId));
		item.setDiscrepancyType(value(request, "discrepancyType", assetItemId));
		item.setDiscrepancyNote(value(request, "discrepancyNote", assetItemId));
		return item;
	}

	private int intValue(HttpServletRequest request, String prefix, Long assetItemId) {
		String value = request.getParameter(prefix + "_" + assetItemId);
		return value == null || value.isBlank() ? 0 : Integer.parseInt(value);
	}

	private String value(HttpServletRequest request, String prefix, Long assetItemId) {
		return request.getParameter(prefix + "_" + assetItemId);
	}

	private long idFrom(String path) {
		return Long.parseLong(path.split("/")[1]);
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {
		request.setAttribute("roleBase", roleBase());
		request.setAttribute("roleName", roleName());
		request.getRequestDispatcher("/WEB-INF/views/shared/inspections/" + view).forward(request, response);
	}
}
