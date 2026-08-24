package fpt.swp391.labtoolequip.controller;

import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.auth.Csrf;
import fpt.swp391.labtoolequip.dao.InspectionDAO;
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

		List<InspectionItem> targets = dao.findInspectableTargets();

		Map<String, InspectionItem> itemByTarget = items.stream()
				.collect(Collectors.toMap(InspectionItem::getRowKey, item -> item, (first, second) -> first));

		request.setAttribute("inspection", inspection);

		request.setAttribute("items", items);

		request.setAttribute("itemByTarget", itemByTarget);

		/*
		 * Keep the attribute name "assets" because the FE-05 form currently iterates
		 * over this collection.
		 *
		 * Each element is actually an InspectionItem target: - QUANTITY asset -> one
		 * parent row - SERIALIZED asset -> one row per AssetItem
		 */
		request.setAttribute("assets", targets);

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

	/*
	 * Hybrid request parser:
	 *
	 * targetKey is: - assetId for QUANTITY assets - item_<assetItemId> for
	 * SERIALIZED rows
	 */
	private List<InspectionItem> itemsFrom(HttpServletRequest request, String scope) {

		Set<Long> selected = selectedAssets(request, scope);

		String[] targetKeys = request.getParameterValues("targetKey");

		List<InspectionItem> items = new ArrayList<>();

		if (targetKeys == null) {
			return items;
		}

		for (String targetKey : targetKeys) {

			if (targetKey == null || targetKey.isBlank()) {
				continue;
			}

			InspectionItem item = itemFrom(request, targetKey);

			if ("WHOLE_LAB".equals(scope) || selected.contains(item.getAssetId())) {

				items.add(item);
			}
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

	private Set<Long> selectedAssets(HttpServletRequest request, String scope) {

		String[] values = request.getParameterValues("selectedAssetId");

		if (values == null) {
			return Set.of();
		}

		return java.util.Arrays.stream(values).filter(value -> value != null && !value.isBlank()).map(Long::parseLong)
				.collect(Collectors.toCollection(java.util.LinkedHashSet::new));
	}

	private InspectionItem itemFrom(HttpServletRequest request, String targetKey) {

		InspectionItem item = new InspectionItem();

		item.setAssetId(Long.parseLong(request.getParameter("assetId_" + targetKey)));

		String assetItemId = request.getParameter("assetItemId_" + targetKey);

		if (assetItemId != null && !assetItemId.isBlank()) {

			item.setAssetItemId(Long.parseLong(assetItemId));
		}

		item.setExpectedQuantity(intValue(request, "expectedQuantity", targetKey));

		item.setActualQuantity(intValue(request, "actualQuantity", targetKey));

		item.setExpectedCondition(value(request, "expectedCondition", targetKey));

		item.setActualCondition(value(request, "actualCondition", targetKey));

		item.setDiscrepancyType(value(request, "discrepancyType", targetKey));

		item.setDiscrepancyNote(value(request, "discrepancyNote", targetKey));

		return item;
	}

	private int intValue(HttpServletRequest request, String prefix, String targetKey) {

		String value = request.getParameter(prefix + "_" + targetKey);

		return value == null || value.isBlank() ? 0 : Integer.parseInt(value);
	}

	private String value(HttpServletRequest request, String prefix, String targetKey) {

		return request.getParameter(prefix + "_" + targetKey);
	}

	private long idFrom(String path) {
		return Long.parseLong(path.split("/")[1]);
	}

	private void forward(HttpServletRequest request, HttpServletResponse response, String view)
			throws ServletException, IOException {

		request.setAttribute("roleBase", roleBase());

		request.setAttribute("roleName", roleName());

		/*
		 * Keep FE-05 aligned with the project's CSRF mechanism.
		 */
		request.setAttribute("csrfToken", Csrf.token(request));

		request.getRequestDispatcher("/WEB-INF/views/shared/inspections/" + view).forward(request, response);
	}
}