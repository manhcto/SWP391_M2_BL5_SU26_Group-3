package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.common.ViewFormat;
import fpt.swp391.labtoolequip.model.Asset;
import fpt.swp391.labtoolequip.model.AssetItem;
import fpt.swp391.labtoolequip.model.EquipmentActivity;
import fpt.swp391.labtoolequip.model.EquipmentAllocation;
import fpt.swp391.labtoolequip.model.EquipmentAllocationRequest;
import fpt.swp391.labtoolequip.model.EquipmentIssueReport;
import fpt.swp391.labtoolequip.model.InternList;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

public class EquipmentAllocationDAO {
	private final DBConnection db = new DBConnection();

	public List<InternList> findApprovedInternLists(long mentorId) throws SQLException {
		String sql = """
				SELECT r.request_id, r.group_name, s.code AS semester_code, s.name AS semester_name
				FROM dbo.lab_usage_requests r JOIN dbo.semesters s ON s.semester_id = r.semester_id
				WHERE r.mentor_id = ? AND r.status = 'APPROVED' ORDER BY s.start_date DESC
				""";
		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, mentorId);
			try (ResultSet result = statement.executeQuery()) {
				List<InternList> lists = new ArrayList<>();
				while (result.next()) { InternList list = new InternList(); list.setRequestId(result.getLong(1)); list.setGroupName(result.getString(2)); list.setSemesterCode(result.getString(3)); list.setSemesterName(result.getString(4)); lists.add(list); }
				return lists;
			}
		}
	}

	public List<EquipmentActivity> findActivitiesForMentor(long mentorId) throws SQLException {
		return activities("WHERE ea.mentor_id = ?", mentorId);
	}

	public List<EquipmentActivity> findActivitiesForMentor(long mentorId, String keyword, String status, LocalDate fromDate, LocalDate toDate) throws SQLException {
		StringBuilder sql = new StringBuilder("SELECT ea.*, s.code AS semester_code, r.group_name FROM dbo.equipment_activities ea JOIN dbo.lab_usage_requests r ON r.request_id=ea.request_id JOIN dbo.semesters s ON s.semester_id=r.semester_id WHERE ea.mentor_id=?");
		List<Object> values = new ArrayList<>(); values.add(mentorId);
		if (!blank(keyword)) { sql.append(" AND (ea.activity_name LIKE ? OR r.group_name LIKE ?)"); values.add("%" + keyword.trim() + "%"); values.add("%" + keyword.trim() + "%"); }
		if (status != null && Set.of("ACTIVE", "CLOSED", "CANCELLED").contains(status)) { sql.append(" AND ea.status=?"); values.add(status); }
		if (fromDate != null) { sql.append(" AND ea.start_date>=?"); values.add(Date.valueOf(fromDate)); }
		if (toDate != null) { sql.append(" AND ea.end_date<=?"); values.add(Date.valueOf(toDate)); }
		sql.append(" ORDER BY ea.start_date DESC, ea.activity_id DESC");
		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {
			for (int index = 0; index < values.size(); index++) statement.setObject(index + 1, values.get(index));
			return readActivities(statement);
		}
	}

	public List<EquipmentActivity> findActivitiesForIntern(long userId) throws SQLException {
		String where = """
				JOIN dbo.lab_usage_request_students members ON members.request_id = ea.request_id
				JOIN dbo.student_profiles ip ON ip.student_id = members.student_id
				WHERE ip.user_id = ?
				""";
		return activities(where, userId);
	}

	private List<EquipmentActivity> activities(String tail, long userId) throws SQLException {
		String sql = """
				SELECT ea.*, s.code AS semester_code, r.group_name
				FROM dbo.equipment_activities ea
				JOIN dbo.lab_usage_requests r ON r.request_id = ea.request_id
				JOIN dbo.semesters s ON s.semester_id = r.semester_id
				""" + tail + " ORDER BY ea.start_date DESC, ea.activity_id DESC";
		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, userId);
			return readActivities(statement);
		}
	}

	public EquipmentActivity findActivity(long id, long mentorId) throws SQLException {
		String sql = """
				SELECT ea.*, s.code AS semester_code, r.group_name
				FROM dbo.equipment_activities ea JOIN dbo.lab_usage_requests r ON r.request_id = ea.request_id
				JOIN dbo.semesters s ON s.semester_id = r.semester_id WHERE ea.activity_id = ? AND ea.mentor_id = ?
				""";
		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, id); statement.setLong(2, mentorId);
			return readActivities(statement).stream().findFirst().orElse(null);
		}
	}

	public long createActivityWithRequests(long mentorId, EquipmentActivity activity,
			List<EquipmentAllocationRequest> requests) throws SQLException {
		validateActivity(activity);
		validateRequestRows(requests);
		try (Connection connection = db.getConnection()) {
			connection.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
			connection.setAutoCommit(false);
			try {
				validateInternList(connection, mentorId, activity);
				long activityId;
				String activitySql = "INSERT dbo.equipment_activities (request_id, mentor_id, activity_name, description, start_date, end_date) VALUES (?, ?, ?, ?, ?, ?)";
				try (PreparedStatement statement = connection.prepareStatement(activitySql, java.sql.Statement.RETURN_GENERATED_KEYS)) {
					statement.setLong(1, activity.getInternListId()); statement.setLong(2, mentorId); statement.setString(3, activity.getActivityName().trim()); nullable(statement, 4, activity.getDescription()); statement.setDate(5, Date.valueOf(activity.getStartDate())); statement.setDate(6, Date.valueOf(activity.getEndDate())); statement.executeUpdate();
					try (ResultSet keys = statement.getGeneratedKeys()) { keys.next(); activityId = keys.getLong(1); }
				}
				String assetSql = """
						SELECT 1 FROM dbo.assets asset
						WHERE asset.asset_id=? AND asset.status='AVAILABLE' AND asset.is_borrowable=1
						AND EXISTS (SELECT 1 FROM dbo.asset_items item WHERE item.asset_id=asset.asset_id
						    AND item.status='AVAILABLE' AND item.is_borrowable=1 AND item.condition IN ('GOOD','FAIR'))
						""";
				String requestSql = "INSERT dbo.equipment_allocation_requests (activity_id, asset_id, requested_quantity, note, requested_by) VALUES (?, ?, ?, ?, ?)";
				try (PreparedStatement asset = connection.prepareStatement(assetSql); PreparedStatement insert = connection.prepareStatement(requestSql)) {
					for (EquipmentAllocationRequest request : requests) {
						asset.setLong(1, request.getAssetId());
						try (ResultSet result = asset.executeQuery()) { if (!result.next()) throw new IllegalArgumentException("Tài sản đã chọn không còn khả dụng để cấp phát."); }
						insert.setLong(1, activityId); insert.setLong(2, request.getAssetId()); insert.setInt(3, request.getRequestedQuantity()); nullable(insert, 4, request.getNote()); insert.setLong(5, mentorId); insert.addBatch();
					}
					insert.executeBatch();
				}
				connection.commit();
				return activityId;
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public void updateActivity(long mentorId, EquipmentActivity activity) throws SQLException {
		if (activity.getActivityId() == null) throw new IllegalArgumentException("Hoạt động không hợp lệ.");
		validateActivity(activity);
		String sql = "UPDATE dbo.equipment_activities SET activity_name=?, description=?, start_date=?, end_date=?, updated_at=SYSUTCDATETIME() WHERE activity_id=? AND mentor_id=? AND request_id=? AND status='ACTIVE'";
		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, activity.getActivityName().trim()); nullable(statement, 2, activity.getDescription()); statement.setDate(3, Date.valueOf(activity.getStartDate())); statement.setDate(4, Date.valueOf(activity.getEndDate())); statement.setLong(5, activity.getActivityId()); statement.setLong(6, mentorId); statement.setLong(7, activity.getInternListId());
			if (statement.executeUpdate() != 1) throw new IllegalArgumentException("Hoạt động không còn có thể chỉnh sửa.");
		}
	}

	public List<Asset> findRequestableAssets() throws SQLException {
		String sql = """
				SELECT a.asset_id, a.asset_code, a.asset_name, COUNT(*) AS available_quantity
				FROM dbo.assets a JOIN dbo.asset_items ai ON ai.asset_id = a.asset_id
				WHERE a.status = 'AVAILABLE' AND a.is_borrowable = 1
				  AND ai.status = 'AVAILABLE' AND ai.is_borrowable = 1 AND ai.condition IN ('GOOD', 'FAIR')
				  AND NOT EXISTS (SELECT 1 FROM dbo.equipment_allocations ea WHERE ea.asset_item_id = ai.asset_item_id AND ea.status IN ('READY_FOR_HANDOVER', 'ACTIVE', 'ISSUE_REPORTED'))
				  AND NOT EXISTS (SELECT 1 FROM dbo.asset_usages usage WHERE usage.asset_item_id = ai.asset_item_id AND usage.status IN ('IN_USE', 'RETURN_PENDING'))
				GROUP BY a.asset_id, a.asset_code, a.asset_name ORDER BY a.asset_name
				""";
		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement(sql); ResultSet result = statement.executeQuery()) {
			List<Asset> assets = new ArrayList<>(); while (result.next()) { Asset asset = new Asset(); asset.setAssetId(result.getLong(1)); asset.setAssetCode(result.getString(2)); asset.setAssetName(result.getString(3)); asset.setTotalQuantity(result.getInt(4)); assets.add(asset); } return assets;
		}
	}

	public List<EquipmentAllocationRequest> findRequestsForMentor(long mentorId) throws SQLException { return requests("WHERE activity.mentor_id = ?", mentorId); }
	public List<EquipmentAllocationRequest> findRequestsForManager() throws SQLException { return requests("", null); }

	private List<EquipmentAllocationRequest> requests(String tail, Long userId) throws SQLException {
		String sql = """
				SELECT ar.*, activity.activity_name, asset.asset_name, asset.asset_code, mentor.full_name,
				       COALESCE(intern.full_name, intern_list.group_name) AS target_name
				FROM dbo.equipment_allocation_requests ar
				JOIN dbo.equipment_activities activity ON activity.activity_id = ar.activity_id
				JOIN dbo.lab_usage_requests intern_list ON intern_list.request_id = activity.request_id
				JOIN dbo.assets asset ON asset.asset_id = ar.asset_id
				JOIN dbo.users mentor ON mentor.user_id = ar.requested_by
				LEFT JOIN dbo.student_profiles ip ON ip.student_id = ar.intern_id
				LEFT JOIN dbo.users intern ON intern.user_id = ip.user_id
				""" + tail + " ORDER BY ar.created_at DESC";
		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) { if (userId != null) statement.setLong(1, userId); return readRequests(statement); }
	}

	public EquipmentAllocationRequest findRequest(long id) throws SQLException {
		String sql = "SELECT ar.*, activity.activity_name, asset.asset_name, asset.asset_code, mentor.full_name, COALESCE(intern.full_name, intern_list.group_name) AS target_name FROM dbo.equipment_allocation_requests ar JOIN dbo.equipment_activities activity ON activity.activity_id=ar.activity_id JOIN dbo.lab_usage_requests intern_list ON intern_list.request_id=activity.request_id JOIN dbo.assets asset ON asset.asset_id=ar.asset_id JOIN dbo.users mentor ON mentor.user_id=ar.requested_by LEFT JOIN dbo.student_profiles ip ON ip.student_id=ar.intern_id LEFT JOIN dbo.users intern ON intern.user_id=ip.user_id WHERE ar.allocation_request_id=?";
		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) { statement.setLong(1, id); return readRequests(statement).stream().findFirst().orElse(null); }
	}

	public List<AssetItem> findAvailableItems(long assetId) throws SQLException {
		String sql = """
				SELECT ai.asset_item_id, ai.item_code, ai.serial_number, ai.condition, ai.status
				FROM dbo.asset_items ai JOIN dbo.assets asset ON asset.asset_id=ai.asset_id
				WHERE ai.asset_id = ? AND asset.status='AVAILABLE' AND asset.is_borrowable=1
				AND ai.status = 'AVAILABLE' AND ai.is_borrowable=1 AND ai.condition IN ('GOOD','FAIR')
				AND NOT EXISTS (SELECT 1 FROM dbo.equipment_allocations ea WHERE ea.asset_item_id = ai.asset_item_id AND ea.status IN ('READY_FOR_HANDOVER', 'ACTIVE', 'ISSUE_REPORTED'))
				AND NOT EXISTS (SELECT 1 FROM dbo.asset_usages usage WHERE usage.asset_item_id = ai.asset_item_id AND usage.status IN ('IN_USE', 'RETURN_PENDING')) ORDER BY ai.item_code
				""";
		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) { statement.setLong(1, assetId); try (ResultSet result = statement.executeQuery()) { List<AssetItem> items = new ArrayList<>(); while (result.next()) { AssetItem item = new AssetItem(); item.setAssetItemId(result.getLong(1)); item.setItemCode(result.getString(2)); item.setSerialNumber(result.getString(3)); item.setCondition(result.getString(4)); item.setStatus(result.getString(5)); items.add(item); } return items; } }
	}

	public void approveRequest(long requestId, long managerId, String[] itemValues, String note) throws SQLException {
		if (itemValues == null || itemValues.length == 0) throw new IllegalArgumentException("Vui lòng chọn thiết bị cụ thể để cấp phát.");
		if (note != null && note.trim().length() > 500) throw new IllegalArgumentException("Ghi chú duyệt không được vượt quá 500 ký tự.");
		try (Connection connection = db.getConnection()) { connection.setAutoCommit(false); try {
			EquipmentAllocationRequest request = lockRequest(connection, requestId); if (request == null || !"PENDING_APPROVAL".equals(request.getStatus())) throw new IllegalArgumentException("Yêu cầu không còn chờ duyệt.");
			Set<Long> selectedItems = selectedItemIds(itemValues, request.getRequestedQuantity());
			if (countAvailableItems(connection, request.getAssetId()) < request.getRequestedQuantity()) throw new IllegalArgumentException("Tồn kho hiện không đủ " + request.getRequestedQuantity() + " thiết bị khả dụng.");
			String allocationStatus = request.getInternId() == null ? "ACTIVE" : "READY_FOR_HANDOVER";
			for (long itemId : selectedItems) { if (!availableItem(connection, itemId, request.getAssetId())) throw new IllegalArgumentException("Có thiết bị không còn sẵn sàng."); try (PreparedStatement statement = connection.prepareStatement("INSERT dbo.equipment_allocations (allocation_request_id, asset_item_id, status, handed_over_by, handed_over_at) VALUES (?, ?, ?, ?, SYSUTCDATETIME())")) { statement.setLong(1, requestId); statement.setLong(2, itemId); statement.setString(3, allocationStatus); statement.setLong(4, managerId); statement.executeUpdate(); } try (PreparedStatement statement = connection.prepareStatement("UPDATE dbo.asset_items SET status=?, updated_at=SYSUTCDATETIME() WHERE asset_item_id=? AND status='AVAILABLE'")) { statement.setString(1, "ACTIVE".equals(allocationStatus) ? "IN_USE" : "UNAVAILABLE"); statement.setLong(2, itemId); if (statement.executeUpdate()!=1) throw new IllegalArgumentException("Có thiết bị vừa được cấp phát cho yêu cầu khác."); } }
			try (PreparedStatement statement = connection.prepareStatement("UPDATE dbo.equipment_allocation_requests SET status='APPROVED', reviewed_by=?, reviewed_at=SYSUTCDATETIME(), review_note=?, updated_at=SYSUTCDATETIME() WHERE allocation_request_id=?")) { statement.setLong(1, managerId); nullable(statement, 2, note); statement.setLong(3, requestId); statement.executeUpdate(); }
			connection.commit();
		} catch (SQLException | RuntimeException exception) { connection.rollback(); throw exception; } }
	}

	public void recoverAllocation(long allocationId, long managerId, String returnCondition, String note) throws SQLException {
		if (!Set.of("GOOD", "FAIR", "DAMAGED", "BROKEN").contains(returnCondition)) throw new IllegalArgumentException("Tình trạng khi thu hồi không hợp lệ.");
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try (PreparedStatement lock = connection.prepareStatement("SELECT asset_item_id FROM dbo.equipment_allocations WITH (UPDLOCK, HOLDLOCK) WHERE allocation_id=? AND status IN ('ACTIVE', 'ISSUE_REPORTED')")) {
				lock.setLong(1, allocationId);
				long itemId;
				try (ResultSet result = lock.executeQuery()) { if (!result.next()) throw new IllegalArgumentException("Thiết bị chưa thể thu hồi."); itemId = result.getLong(1); }
				try (PreparedStatement update = connection.prepareStatement("UPDATE dbo.equipment_allocations SET status='RETURNED', recovered_by=?, recovered_at=SYSUTCDATETIME(), return_condition=?, return_note=? WHERE allocation_id=?")) { update.setLong(1, managerId); update.setString(2, returnCondition); nullable(update, 3, note); update.setLong(4, allocationId); update.executeUpdate(); }
				String itemStatus = Set.of("DAMAGED", "BROKEN").contains(returnCondition) ? "MAINTENANCE" : "AVAILABLE";
				try (PreparedStatement update = connection.prepareStatement("UPDATE dbo.asset_items SET condition=?, status=?, updated_at=SYSUTCDATETIME() WHERE asset_item_id=?")) { update.setString(1, returnCondition); update.setString(2, itemStatus); update.setLong(3, itemId); update.executeUpdate(); }
				connection.commit();
			} catch (SQLException | RuntimeException exception) { connection.rollback(); throw exception; }
		}
	}

	public List<EquipmentAllocation> findAllocationsForIntern(long userId) throws SQLException { return allocations("WHERE direct.user_id = ? OR EXISTS (SELECT 1 FROM dbo.lab_usage_request_students class_students JOIN dbo.student_profiles class_profile ON class_profile.student_id=class_students.student_id WHERE class_students.request_id=activity.request_id AND class_profile.user_id=?)", userId, userId); }
	public List<EquipmentAllocation> findAllocationsForManager() throws SQLException { return allocations(""); }

	private List<EquipmentAllocation> allocations(String tail, Long... userIds) throws SQLException {
		String sql = """
				SELECT allocation.*, request.allocation_request_id, activity.activity_name, asset.asset_name, item.item_code, item.condition,
				       COALESCE(direct.full_name, intern_list.group_name) AS target_name
				FROM dbo.equipment_allocations allocation JOIN dbo.equipment_allocation_requests request ON request.allocation_request_id=allocation.allocation_request_id
				JOIN dbo.equipment_activities activity ON activity.activity_id=request.activity_id JOIN dbo.lab_usage_requests intern_list ON intern_list.request_id=activity.request_id JOIN dbo.asset_items item ON item.asset_item_id=allocation.asset_item_id
				JOIN dbo.assets asset ON asset.asset_id=item.asset_id
				LEFT JOIN dbo.student_profiles direct_profile ON direct_profile.student_id=request.intern_id LEFT JOIN dbo.users direct ON direct.user_id=direct_profile.user_id
				""" + tail + " ORDER BY allocation.allocation_id DESC";
		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) { for (int i=0;i<userIds.length;i++) statement.setLong(i+1,userIds[i]); return readAllocations(statement); }
	}

	public void confirmReceipt(long allocationId, long userId) throws SQLException {
		String sql = """
				UPDATE allocation SET status='ACTIVE', received_at=SYSUTCDATETIME()
				FROM dbo.equipment_allocations allocation JOIN dbo.equipment_allocation_requests request ON request.allocation_request_id=allocation.allocation_request_id
				LEFT JOIN dbo.student_profiles direct_profile ON direct_profile.student_id=request.intern_id
				WHERE allocation.allocation_id=? AND allocation.status='READY_FOR_HANDOVER' AND direct_profile.user_id=?
				""";
		try (Connection connection=db.getConnection()) { connection.setAutoCommit(false); try (PreparedStatement statement=connection.prepareStatement(sql)) { statement.setLong(1,allocationId); statement.setLong(2,userId); if(statement.executeUpdate()!=1) throw new IllegalArgumentException("Không thể xác nhận bàn giao thiết bị này."); try (PreparedStatement update = connection.prepareStatement("UPDATE dbo.asset_items SET status='IN_USE', updated_at=SYSUTCDATETIME() WHERE asset_item_id=(SELECT asset_item_id FROM dbo.equipment_allocations WHERE allocation_id=?)")) { update.setLong(1, allocationId); update.executeUpdate(); } connection.commit(); } catch (SQLException | RuntimeException exception) { connection.rollback(); throw exception; } }
	}

	public void reportIssue(long allocationId, long userId, String type, String description, String imagePath) throws SQLException {
		if (!Set.of("DAMAGE","LOSS","MISSING_COMPONENT").contains(type) || blank(description)) throw new IllegalArgumentException("Vui lòng nhập loại và mô tả sự cố.");
		String sql = "INSERT dbo.equipment_allocation_issue_reports (allocation_id, reported_by, issue_type, description, image_path) "
				+ "SELECT ?, ?, ?, ?, ? WHERE EXISTS (SELECT 1 FROM dbo.equipment_allocations a JOIN dbo.equipment_allocation_requests r ON r.allocation_request_id=a.allocation_request_id JOIN dbo.equipment_activities activity ON activity.activity_id=r.activity_id LEFT JOIN dbo.student_profiles direct ON direct.student_id=r.intern_id LEFT JOIN dbo.lab_usage_request_students class_students ON class_students.request_id=activity.request_id LEFT JOIN dbo.student_profiles class_profile ON class_profile.student_id=class_students.student_id WHERE a.allocation_id=? AND a.status='ACTIVE' AND (direct.user_id=? OR class_profile.user_id=?))";
		try(Connection c=db.getConnection();PreparedStatement s=c.prepareStatement(sql)){s.setLong(1,allocationId);s.setLong(2,userId);s.setString(3,type);s.setString(4,description.trim());nullable(s,5,imagePath);s.setLong(6,allocationId);s.setLong(7,userId);s.setLong(8,userId);if(s.executeUpdate()!=1)throw new IllegalArgumentException("Bạn không thể báo sự cố cho thiết bị này.");}
	}

	public List<EquipmentIssueReport> findIssuesForMentor(long mentorId) throws SQLException {
		String sql = "SELECT issue.*, reporter.full_name, activity.activity_name, item.item_code FROM dbo.equipment_allocation_issue_reports issue JOIN dbo.equipment_allocations allocation ON allocation.allocation_id=issue.allocation_id JOIN dbo.equipment_allocation_requests request ON request.allocation_request_id=allocation.allocation_request_id JOIN dbo.equipment_activities activity ON activity.activity_id=request.activity_id JOIN dbo.asset_items item ON item.asset_item_id=allocation.asset_item_id JOIN dbo.users reporter ON reporter.user_id=issue.reported_by WHERE activity.mentor_id=? ORDER BY issue.created_at DESC";
		try(Connection c=db.getConnection();PreparedStatement s=c.prepareStatement(sql)){s.setLong(1,mentorId);return readIssues(s);}
	}

	public void reviewIssue(long issueId,long mentorId,boolean verified,String note)throws SQLException{
		try(Connection c=db.getConnection()){c.setAutoCommit(false);try{
			String lock = "SELECT issue.allocation_id, issue.issue_type, issue.description, allocation.asset_item_id, item.asset_id FROM dbo.equipment_allocation_issue_reports issue JOIN dbo.equipment_allocations allocation ON allocation.allocation_id=issue.allocation_id JOIN dbo.equipment_allocation_requests request ON request.allocation_request_id=allocation.allocation_request_id JOIN dbo.equipment_activities activity ON activity.activity_id=request.activity_id JOIN dbo.asset_items item ON item.asset_item_id=allocation.asset_item_id WHERE issue.issue_report_id=? AND issue.status='PENDING_MENTOR' AND activity.mentor_id=?";
			long allocationId,itemId,assetId;String type,description;try(PreparedStatement s=c.prepareStatement(lock)){s.setLong(1,issueId);s.setLong(2,mentorId);try(ResultSet r=s.executeQuery()){if(!r.next())throw new IllegalArgumentException("Báo cáo không còn chờ xác minh.");allocationId=r.getLong(1);type=r.getString(2);description=r.getString(3);itemId=r.getLong(4);assetId=r.getLong(5);}}
			Long incidentId=null;if(verified){try(PreparedStatement s=c.prepareStatement("INSERT dbo.incidents (asset_id, asset_item_id, reported_by, affected_quantity, incident_type, description, severity, status, occurred_at, reported_cause) OUTPUT INSERTED.incident_id VALUES (?, ?, ?, 1, ?, ?, 'HIGH', 'OPEN', SYSUTCDATETIME(), 'UNKNOWN')")){s.setLong(1,assetId);s.setLong(2,itemId);s.setLong(3,mentorId);s.setString(4,"LOSS".equals(type)?"LOSS":"DAMAGE");s.setString(5,description);try(ResultSet r=s.executeQuery()){r.next();incidentId=r.getLong(1);}}
				try(PreparedStatement s=c.prepareStatement("UPDATE dbo.equipment_allocations SET status='ISSUE_REPORTED' WHERE allocation_id=?")){s.setLong(1,allocationId);s.executeUpdate();}
				try(PreparedStatement s=c.prepareStatement("UPDATE dbo.asset_items SET status=?, updated_at=SYSUTCDATETIME() WHERE asset_item_id=?")){s.setString(1,"LOSS".equals(type)?"UNAVAILABLE":"MAINTENANCE");s.setLong(2,itemId);s.executeUpdate();}}
			try(PreparedStatement s=c.prepareStatement("UPDATE dbo.equipment_allocation_issue_reports SET status=?, mentor_note=?, incident_id=?, reviewed_by=?, reviewed_at=SYSUTCDATETIME() WHERE issue_report_id=?")){s.setString(1,verified?"VERIFIED":"REJECTED");nullable(s,2,note);nullableLong(s,3,incidentId);s.setLong(4,mentorId);s.setLong(5,issueId);s.executeUpdate();}
			c.commit();
		}catch(SQLException|RuntimeException e){c.rollback();throw e;}}
	}

	private EquipmentAllocationRequest lockRequest(Connection c,long id)throws SQLException{try(PreparedStatement s=c.prepareStatement("SELECT * FROM dbo.equipment_allocation_requests WITH (UPDLOCK,HOLDLOCK) WHERE allocation_request_id=?")){s.setLong(1,id);return readRequests(s).stream().findFirst().orElse(null);}}
	private boolean availableItem(Connection c,long id,long assetId)throws SQLException{try(PreparedStatement s=c.prepareStatement("SELECT 1 FROM dbo.asset_items item WITH (UPDLOCK,HOLDLOCK) JOIN dbo.assets asset ON asset.asset_id=item.asset_id WHERE item.asset_item_id=? AND item.asset_id=? AND asset.status='AVAILABLE' AND asset.is_borrowable=1 AND item.status='AVAILABLE' AND item.is_borrowable=1 AND item.condition IN ('GOOD','FAIR') AND NOT EXISTS (SELECT 1 FROM dbo.equipment_allocations allocation WHERE allocation.asset_item_id=item.asset_item_id AND allocation.status IN ('READY_FOR_HANDOVER','ACTIVE','ISSUE_REPORTED')) AND NOT EXISTS (SELECT 1 FROM dbo.asset_usages usage WHERE usage.asset_item_id=item.asset_item_id AND usage.status IN ('IN_USE','RETURN_PENDING'))")){s.setLong(1,id);s.setLong(2,assetId);try(ResultSet r=s.executeQuery()){return r.next();}}}
	private int countAvailableItems(Connection c,long assetId)throws SQLException{try(PreparedStatement s=c.prepareStatement("SELECT COUNT(*) FROM dbo.asset_items item WITH (UPDLOCK,HOLDLOCK) JOIN dbo.assets asset ON asset.asset_id=item.asset_id WHERE item.asset_id=? AND asset.status='AVAILABLE' AND asset.is_borrowable=1 AND item.status='AVAILABLE' AND item.is_borrowable=1 AND item.condition IN ('GOOD','FAIR') AND NOT EXISTS (SELECT 1 FROM dbo.equipment_allocations allocation WHERE allocation.asset_item_id=item.asset_item_id AND allocation.status IN ('READY_FOR_HANDOVER','ACTIVE','ISSUE_REPORTED')) AND NOT EXISTS (SELECT 1 FROM dbo.asset_usages usage WHERE usage.asset_item_id=item.asset_item_id AND usage.status IN ('IN_USE','RETURN_PENDING'))")){s.setLong(1,assetId);try(ResultSet r=s.executeQuery()){r.next();return r.getInt(1);}}}
	private List<EquipmentActivity> readActivities(PreparedStatement s)throws SQLException{try(ResultSet r=s.executeQuery()){List<EquipmentActivity> list=new ArrayList<>();while(r.next()){EquipmentActivity a=new EquipmentActivity();a.setActivityId(r.getLong("activity_id"));a.setInternListId(r.getLong("request_id"));a.setMentorId(r.getLong("mentor_id"));a.setActivityName(r.getString("activity_name"));a.setDescription(r.getString("description"));a.setStartDate(r.getDate("start_date").toLocalDate());a.setEndDate(r.getDate("end_date").toLocalDate());a.setStatus(r.getString("status"));a.setSemesterCode(r.getString("semester_code"));a.setInternListName(r.getString("group_name"));list.add(a);}return list;}}
	private List<EquipmentAllocationRequest> readRequests(PreparedStatement s)throws SQLException{try(ResultSet r=s.executeQuery()){List<EquipmentAllocationRequest> list=new ArrayList<>();while(r.next()){EquipmentAllocationRequest q=new EquipmentAllocationRequest();q.setAllocationRequestId(r.getLong("allocation_request_id"));q.setActivityId(r.getLong("activity_id"));q.setInternId(nullableLong(r,"intern_id"));q.setAssetId(r.getLong("asset_id"));q.setRequestedQuantity(r.getInt("requested_quantity"));q.setNote(r.getString("note"));q.setStatus(r.getString("status"));q.setActivityName(column(r,"activity_name"));q.setAssetName(column(r,"asset_name"));q.setAssetCode(column(r,"asset_code"));q.setTargetName(column(r,"target_name"));q.setMentorName(column(r,"full_name"));q.setCreatedAt(ViewFormat.fromUtc(r.getTimestamp("created_at")));list.add(q);}return list;}}
	private List<EquipmentAllocation> readAllocations(PreparedStatement s)throws SQLException{try(ResultSet r=s.executeQuery()){List<EquipmentAllocation> list=new ArrayList<>();while(r.next()){EquipmentAllocation a=new EquipmentAllocation();a.setAllocationId(r.getLong("allocation_id"));a.setAllocationRequestId(r.getLong("allocation_request_id"));a.setAssetItemId(r.getLong("asset_item_id"));a.setStatus(r.getString("status"));a.setActivityName(r.getString("activity_name"));a.setTargetName(r.getString("target_name"));a.setAssetName(r.getString("asset_name"));a.setItemCode(r.getString("item_code"));a.setCondition(r.getString("condition"));a.setHandedOverAt(ViewFormat.fromUtc(r.getTimestamp("handed_over_at")));a.setReceivedAt(ViewFormat.fromUtc(r.getTimestamp("received_at")));a.setRecoveredAt(ViewFormat.fromUtc(r.getTimestamp("recovered_at")));list.add(a);}return list;}}
	private List<EquipmentIssueReport> readIssues(PreparedStatement s)throws SQLException{try(ResultSet r=s.executeQuery()){List<EquipmentIssueReport> list=new ArrayList<>();while(r.next()){EquipmentIssueReport i=new EquipmentIssueReport();i.setIssueReportId(r.getLong("issue_report_id"));i.setAllocationId(r.getLong("allocation_id"));i.setIssueType(r.getString("issue_type"));i.setDescription(r.getString("description"));i.setImagePath(r.getString("image_path"));i.setStatus(r.getString("status"));i.setMentorNote(r.getString("mentor_note"));i.setReporterName(r.getString("full_name"));i.setActivityName(r.getString("activity_name"));i.setItemCode(r.getString("item_code"));i.setCreatedAt(ViewFormat.fromUtc(r.getTimestamp("created_at")));list.add(i);}return list;}}
	private String column(ResultSet r,String name)throws SQLException{try{return r.getString(name);}catch(SQLException e){return null;}}
	private Long nullableLong(ResultSet r,String name)throws SQLException{long value=r.getLong(name);return r.wasNull()?null:value;}
	private void nullable(PreparedStatement s,int index,String value)throws SQLException{if(blank(value))s.setNull(index,Types.NVARCHAR);else s.setString(index,value.trim());}
	private void nullableLong(PreparedStatement s,int index,Long value)throws SQLException{if(value==null)s.setNull(index,Types.BIGINT);else s.setLong(index,value);}
	private boolean blank(String value){return value==null||value.isBlank();}
	private void validateActivity(EquipmentActivity activity) {
		if (activity.getInternListId() == null || blank(activity.getActivityName()) || activity.getActivityName().trim().length() < 3 || activity.getActivityName().trim().length() > 150 || activity.getStartDate() == null || activity.getEndDate() == null || activity.getEndDate().isBefore(activity.getStartDate())) throw new IllegalArgumentException("Thông tin hoạt động không hợp lệ.");
		if (activity.getDescription() != null && activity.getDescription().trim().length() > 500) throw new IllegalArgumentException("Mô tả hoạt động không được vượt quá 500 ký tự.");
	}
	static void validateRequestRows(List<EquipmentAllocationRequest> requests) {
		if (requests == null || requests.isEmpty()) throw new IllegalArgumentException("Hãy thêm ít nhất một tài sản.");
		Set<Long> assetIds = new java.util.HashSet<>();
		for (EquipmentAllocationRequest request : requests) {
			if (request.getAssetId() == null || request.getRequestedQuantity() < 1 || request.getRequestedQuantity() > 999 || !assetIds.add(request.getAssetId())) throw new IllegalArgumentException("Mỗi tài sản chỉ được thêm một lần và số lượng phải từ 1 đến 999.");
			if (request.getNote() != null && request.getNote().trim().length() > 500) throw new IllegalArgumentException("Ghi chú không được vượt quá 500 ký tự.");
		}
	}
	static Set<Long> selectedItemIds(String[] itemValues, int requiredQuantity) {
		if (itemValues == null || itemValues.length != requiredQuantity) throw new IllegalArgumentException("Phải chọn đúng " + requiredQuantity + " thiết bị để duyệt yêu cầu.");
		Set<Long> itemIds = new java.util.LinkedHashSet<>();
		for (String value : itemValues) {
			long itemId;
			try { itemId = Long.parseLong(value); } catch (NumberFormatException exception) { throw new IllegalArgumentException("Danh sách thiết bị được chọn không hợp lệ."); }
			if (itemId < 1 || !itemIds.add(itemId)) throw new IllegalArgumentException("Mỗi thiết bị vật lý chỉ được chọn một lần.");
		}
		return itemIds;
	}
	private void validateInternList(Connection connection,long mentorId,EquipmentActivity activity)throws SQLException{
		String sql="SELECT semester.start_date,semester.end_date FROM dbo.lab_usage_requests request WITH (UPDLOCK,HOLDLOCK) JOIN dbo.semesters semester ON semester.semester_id=request.semester_id WHERE request.request_id=? AND request.mentor_id=? AND request.status='APPROVED'";
		try(PreparedStatement statement=connection.prepareStatement(sql)){statement.setLong(1,activity.getInternListId());statement.setLong(2,mentorId);try(ResultSet result=statement.executeQuery()){if(!result.next())throw new IllegalArgumentException("Danh sách Intern chưa được duyệt hoặc không thuộc Mentor.");LocalDate start=result.getDate(1).toLocalDate();LocalDate end=result.getDate(2).toLocalDate();if(activity.getStartDate().isBefore(start)||activity.getEndDate().isAfter(end))throw new IllegalArgumentException("Thời gian yêu cầu phải nằm trong kỳ của danh sách Intern.");}}
		try(PreparedStatement statement=connection.prepareStatement("SELECT 1 FROM dbo.equipment_activities WITH (UPDLOCK,HOLDLOCK) WHERE request_id=? AND status='ACTIVE'")){statement.setLong(1,activity.getInternListId());try(ResultSet result=statement.executeQuery()){if(result.next())throw new IllegalArgumentException("Danh sách Intern này đã có một yêu cầu cấp phát đang hoạt động. Hãy chỉnh sửa yêu cầu hiện có.");}}
	}
}
