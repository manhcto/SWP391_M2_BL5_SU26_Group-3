package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.common.ViewFormat;
import fpt.swp391.labtoolequip.model.Incident;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

public class IncidentDAO {
	private static final String SELECT = """
			SELECT i.*, a.asset_code, a.asset_name, reporter.full_name AS reporter_name,
			       ai.item_code AS asset_item_code,
			       sp.student_code AS intern_code, intern.full_name AS intern_name
			FROM dbo.incidents i
			JOIN dbo.assets a ON a.asset_id = i.asset_id
			JOIN dbo.users reporter ON reporter.user_id = i.reported_by
			LEFT JOIN dbo.asset_usages au ON au.asset_usage_id = i.asset_usage_id
			LEFT JOIN dbo.asset_items ai ON ai.asset_item_id = COALESCE(i.asset_item_id, au.asset_item_id)
			LEFT JOIN dbo.student_profiles sp ON sp.student_id = au.student_id
			LEFT JOIN dbo.users intern ON intern.user_id = sp.user_id
			""";
	private final DBConnection db = new DBConnection();

	public List<Incident> findAll(String keyword, String status, String severity) throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String level = severity == null ? "" : severity.trim();
		String sql = SELECT + """
				WHERE (? = '' OR CAST(i.incident_id AS varchar(30)) LIKE ? OR a.asset_code LIKE ?
				       OR a.asset_name LIKE ? OR ai.item_code LIKE ? OR i.description LIKE ?
				       OR reporter.full_name LIKE ? OR COALESCE(intern.full_name, '') LIKE ?)
				  AND (? = '' OR i.status = ?)
				  AND (? = '' OR i.severity = ?)
				  AND i.severity IN ('HIGH', 'CRITICAL')
				ORDER BY COALESCE(i.occurred_at, i.reported_at) DESC, i.incident_id DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			String pattern = "%" + search + "%";
			int index = 1;
			statement.setString(index++, search);
			for (int count = 0; count < 7; count++)
				statement.setString(index++, pattern);
			statement.setString(index++, state);
			statement.setString(index++, state);
			statement.setString(index++, level);
			statement.setString(index, level);
			return read(statement);
		}
	}

	public List<Incident> findForMentor(long mentorId, String keyword, String status, String severity)
			throws SQLException {
		String search = keyword == null ? "" : keyword.trim();
		String state = status == null ? "" : status.trim();
		String level = severity == null ? "" : severity.trim();
		String sql = SELECT + """
				WHERE i.reported_by = ?
				  AND (? = '' OR CAST(i.incident_id AS varchar(30)) LIKE ? OR a.asset_code LIKE ?
				       OR a.asset_name LIKE ? OR ai.item_code LIKE ? OR i.description LIKE ?)
				  AND (? = '' OR i.status = ?)
				  AND (? = '' OR i.severity = ?)
				  AND i.severity IN ('HIGH', 'CRITICAL')
				ORDER BY COALESCE(i.occurred_at, i.reported_at) DESC, i.incident_id DESC
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			String pattern = "%" + search + "%";
			int index = 1;
			statement.setLong(index++, mentorId);
			statement.setString(index++, search);
			for (int count = 0; count < 5; count++)
				statement.setString(index++, pattern);
			statement.setString(index++, state);
			statement.setString(index++, state);
			statement.setString(index++, level);
			statement.setString(index, level);
			return read(statement);
		}
	}

	public Optional<Incident> findById(long incidentId) throws SQLException {
		String sql = SELECT + """
				WHERE i.incident_id = ? AND i.severity IN ('HIGH', 'CRITICAL')
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, incidentId);
			return read(statement).stream().findFirst();
		}
	}

	public Optional<Incident> findByIdForMentor(long incidentId, long mentorId) throws SQLException {
		String sql = SELECT + """
				WHERE i.incident_id = ? AND i.reported_by = ?
				  AND i.severity IN ('HIGH', 'CRITICAL')
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, incidentId);
			statement.setLong(2, mentorId);
			return read(statement).stream().findFirst();
		}
	}

	public long createForMentor(long mentorId, long usageId, String incidentType, String severity,
			LocalDateTime occurredAt, String description) throws SQLException {
		validateReport(incidentType, severity, description, occurredAt);
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				String targetSql = """
						SELECT au.asset_id, au.quantity
						FROM dbo.asset_usages au WITH (UPDLOCK, HOLDLOCK)
						WHERE au.asset_usage_id = ?
						  AND au.status = 'IN_USE'
						  AND EXISTS (
							SELECT 1 FROM dbo.lab_usage_requests request
							WHERE request.request_id = au.request_id
							  AND request.semester_id = au.semester_id
							  AND request.mentor_id = ? AND request.status = 'APPROVED'
						  )
						  AND NOT EXISTS (
							SELECT 1 FROM dbo.incidents existing
							WHERE existing.asset_usage_id = au.asset_usage_id
							  AND existing.status IN ('OPEN', 'INVESTIGATING')
						  )
						""";
				long assetId;
				int quantity;
				try (PreparedStatement target = connection.prepareStatement(targetSql)) {
					target.setLong(1, usageId);
					target.setLong(2, mentorId);
					try (ResultSet result = target.executeQuery()) {
						if (!result.next()) {
							throw new IllegalStateException(
									"Lượt sử dụng không hợp lệ, không thuộc danh sách bạn phụ trách hoặc đã có sự cố đang chờ xử lý.");
						}
						assetId = result.getLong("asset_id");
						quantity = result.getInt("quantity");
					}
				}
				String insertSql = """
						INSERT dbo.incidents
						(asset_id, asset_usage_id, reported_by, affected_quantity, incident_type, description, severity,
						 status, occurred_at)
						OUTPUT INSERTED.incident_id
						VALUES (?, ?, ?, ?, ?, ?, ?, 'OPEN', ?)
						""";
				try (PreparedStatement insert = connection.prepareStatement(insertSql)) {
					insert.setLong(1, assetId);
					insert.setLong(2, usageId);
					insert.setLong(3, mentorId);
					insert.setInt(4, quantity);
					insert.setString(5, incidentType);
					insert.setString(6, description.trim());
					insert.setString(7, severity);
					if (occurredAt == null) {
						insert.setNull(8, Types.TIMESTAMP);
					} else {
						insert.setTimestamp(8, ViewFormat.toUtc(occurredAt));
					}
					try (ResultSet result = insert.executeQuery()) {
						result.next();
						long incidentId = result.getLong(1);
						moveTargetToMaintenance(connection, new IncidentTarget(assetId, null, usageId, quantity));
						connection.commit();
						return incidentId;
					}
				}
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public List<Long> createForMentor(long mentorId, String[] targetValues, String incidentType, String severity,
			LocalDateTime occurredAt, String description, String reportedCause) throws SQLException {
		validateReport(incidentType, severity, description, occurredAt);
		validateCause(reportedCause);
		if (targetValues == null || targetValues.length == 0)
			throw new IllegalArgumentException("Vui lòng chọn ít nhất một vật dụng hỏng.");
		LinkedHashSet<String> uniqueTargets = new LinkedHashSet<>();
		for (String value : targetValues) {
			if (value != null && !value.isBlank()) uniqueTargets.add(value);
		}
		if (uniqueTargets.isEmpty()) throw new IllegalArgumentException("Vui lòng chọn ít nhất một vật dụng hỏng.");
		try (Connection connection = db.getConnection()) {
			connection.setAutoCommit(false);
			try {
				List<Long> incidentIds = new ArrayList<>();
				for (String value : uniqueTargets) {
					IncidentTarget target = resolveTarget(connection, value);
					if (hasOpenIncident(connection, target))
						throw new IllegalStateException("Vật dụng đã có sự cố đang chờ Lab Manager xử lý.");
					String sql = """
							INSERT dbo.incidents
							(asset_id, asset_item_id, asset_usage_id, reported_by, affected_quantity, incident_type,
							 description, severity, status, occurred_at, reported_cause)
							OUTPUT INSERTED.incident_id
							VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'OPEN', ?, ?)
							""";
					try (PreparedStatement insert = connection.prepareStatement(sql)) {
						insert.setLong(1, target.assetId());
						setNullableLong(insert, 2, target.assetItemId());
						setNullableLong(insert, 3, target.usageId());
						insert.setLong(4, mentorId);
						insert.setInt(5, target.quantity());
						insert.setString(6, incidentType);
						insert.setString(7, description.trim());
						insert.setString(8, severity);
						if (occurredAt == null) insert.setNull(9, Types.TIMESTAMP); else insert.setTimestamp(9, ViewFormat.toUtc(occurredAt));
						insert.setString(10, reportedCause);
						try (ResultSet result = insert.executeQuery()) {
							result.next();
							incidentIds.add(result.getLong(1));
						}
						moveTargetToMaintenance(connection, target);
					}
				}
				connection.commit();
				return incidentIds;
			} catch (SQLException | RuntimeException exception) {
				connection.rollback();
				throw exception;
			}
		}
	}

	public void updateByLabManager(long incidentId, String status, String investigationNote, String handlingResult,
			String determinedCause)
			throws SQLException {
		if (status == null || !Set.of("OPEN", "INVESTIGATING", "RESOLVED", "CLOSED").contains(status)) {
			throw new IllegalArgumentException("Trạng thái xử lý sự cố không hợp lệ.");
		}
		determinedCause = normalizeCause(determinedCause);
		String sql = """
				UPDATE dbo.incidents
				SET status = ?, investigation_note = ?, handling_result = ?, determined_cause = ?, updated_at = SYSUTCDATETIME()
				WHERE incident_id = ? AND severity IN ('HIGH', 'CRITICAL')
				""";
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, status);
			statement.setString(2, blankToNull(investigationNote));
			statement.setString(3, blankToNull(handlingResult));
			statement.setString(4, determinedCause);
			statement.setLong(5, incidentId);
			if (statement.executeUpdate() != 1) {
				throw new IllegalStateException("Không tìm thấy sự cố cần xử lý.");
			}
		}
	}

	static void validateReport(String incidentType, String severity, String description, LocalDateTime occurredAt) {
		if (incidentType == null || !Set.of("DAMAGE", "MISSING", "LOSS", "MALFUNCTION", "OTHER").contains(incidentType)) {
			throw new IllegalArgumentException("Loại sự cố không hợp lệ.");
		}
		if (severity == null || !Set.of("HIGH", "CRITICAL").contains(severity)) {
			throw new IllegalArgumentException("Chỉ gửi báo cáo sự cố mức cao hoặc nghiêm trọng cho Lab Manager.");
		}
		if (description == null || description.isBlank() || description.trim().length() > 2000) {
			throw new IllegalArgumentException("Mô tả sự cố phải có từ 1 đến 2000 ký tự.");
		}
		if (occurredAt != null && occurredAt.isAfter(ViewFormat.now())) {
			throw new IllegalArgumentException("Thời điểm xảy ra không được ở tương lai.");
		}
	}

	private IncidentTarget resolveTarget(Connection connection, String value) throws SQLException {
		boolean usage = value.startsWith("usage:");
		boolean item = value.startsWith("item:");
		if (!usage && !item) throw new IllegalArgumentException("Vật dụng được chọn không hợp lệ.");
		long id;
		try { id = Long.parseLong(value.substring(value.indexOf(':') + 1)); } catch (RuntimeException exception) { throw new IllegalArgumentException("Vật dụng được chọn không hợp lệ."); }
		String sql = usage
				? "SELECT asset_id, asset_item_id, quantity, asset_usage_id FROM dbo.asset_usages WHERE asset_usage_id = ? AND status = 'IN_USE'"
				: "SELECT ai.asset_id, ai.asset_item_id, 1 AS quantity, CAST(NULL AS bigint) AS asset_usage_id FROM dbo.asset_items ai JOIN dbo.assets a ON a.asset_id = ai.asset_id WHERE ai.asset_item_id = ? AND ai.status <> 'DISPOSED' AND a.status <> 'DISPOSED' AND NOT EXISTS (SELECT 1 FROM dbo.asset_usages usage WHERE usage.asset_item_id = ai.asset_item_id AND usage.status IN ('IN_USE', 'MAINTENANCE'))";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, id);
			try (ResultSet result = statement.executeQuery()) {
				if (!result.next()) throw new IllegalArgumentException("Vật dụng không còn đủ điều kiện để báo sự cố.");
				return new IncidentTarget(result.getLong("asset_id"), nullableLong(result, "asset_item_id"), nullableLong(result, "asset_usage_id"), result.getInt("quantity"));
			}
		}
	}

	private boolean hasOpenIncident(Connection connection, IncidentTarget target) throws SQLException {
		String sql = "SELECT 1 FROM dbo.incidents WHERE status IN ('OPEN', 'INVESTIGATING') AND (asset_usage_id = ? OR (? IS NOT NULL AND asset_item_id = ?))";
		try (PreparedStatement statement = connection.prepareStatement(sql)) {
			setNullableLong(statement, 1, target.usageId());
			setNullableLong(statement, 2, target.assetItemId());
			setNullableLong(statement, 3, target.assetItemId());
			try (ResultSet result = statement.executeQuery()) { return result.next(); }
		}
	}

	private void moveTargetToMaintenance(Connection connection, IncidentTarget target) throws SQLException {
		if (target.usageId() != null) {
			try (PreparedStatement statement = connection.prepareStatement("""
					UPDATE dbo.asset_usages SET status = 'MAINTENANCE', updated_at = SYSUTCDATETIME()
					WHERE asset_usage_id = ? AND status = 'IN_USE'
					""")) {
				statement.setLong(1, target.usageId());
				if (statement.executeUpdate() != 1)
					throw new IllegalStateException("Lượt sử dụng đã thay đổi, không thể chuyển sang bảo trì.");
			}
		}
		if (target.assetItemId() != null) {
			try (PreparedStatement statement = connection.prepareStatement("""
					UPDATE dbo.asset_items SET status = 'MAINTENANCE', updated_at = SYSUTCDATETIME()
					WHERE asset_item_id = ? AND status <> 'DISPOSED'
					""")) {
				statement.setLong(1, target.assetItemId());
				if (statement.executeUpdate() != 1) throw new IllegalStateException("Không thể chuyển sản phẩm sang bảo trì.");
			}
			return;
		}
		try (PreparedStatement statement = connection.prepareStatement("""
			UPDATE dbo.assets SET status = 'MAINTENANCE', updated_at = SYSUTCDATETIME()
			WHERE asset_id = ? AND status <> 'DISPOSED'
			""")) {
			statement.setLong(1, target.assetId());
			if (statement.executeUpdate() != 1) throw new IllegalStateException("Không thể chuyển thiết bị sang bảo trì.");
		}
	}

	private void validateCause(String value) {
		if (!Set.of("INTERN", "NATURAL", "UNKNOWN").contains(value))
			throw new IllegalArgumentException("Nguyên nhân sự cố không hợp lệ.");
	}

	private String normalizeCause(String value) {
		if (value == null || value.isBlank()) return null;
		validateCause(value);
		return value;
	}

	private void setNullableLong(PreparedStatement statement, int index, Long value) throws SQLException {
		if (value == null) statement.setNull(index, Types.BIGINT); else statement.setLong(index, value);
	}

	private record IncidentTarget(long assetId, Long assetItemId, Long usageId, int quantity) { }

	private String blankToNull(String value) {
		return value == null || value.isBlank() ? null : value.trim();
	}

	public int countForReporter(long userId) throws SQLException {
		return count("""
				SELECT COUNT(*) FROM dbo.incidents
				WHERE reported_by = ? AND severity IN ('HIGH', 'CRITICAL')
				""", userId);
	}

	public int countForMentor(long mentorId) throws SQLException {
		return count("""
				SELECT COUNT(*)
				FROM dbo.incidents i
				LEFT JOIN dbo.asset_usages au ON au.asset_usage_id = i.asset_usage_id
				LEFT JOIN dbo.lab_usage_requests r ON r.request_id = au.request_id
				WHERE i.severity IN ('HIGH', 'CRITICAL') AND (i.reported_by = ? OR r.mentor_id = ?)
				""", mentorId, mentorId);
	}

	private int count(String sql, long... userIds) throws SQLException {
		try (Connection connection = db.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			for (int index = 0; index < userIds.length; index++)
				statement.setLong(index + 1, userIds[index]);
			try (ResultSet result = statement.executeQuery()) {
				result.next();
				return result.getInt(1);
			}
		}
	}

	private List<Incident> read(PreparedStatement statement) throws SQLException {
		try (ResultSet result = statement.executeQuery()) {
			List<Incident> incidents = new ArrayList<>();
			while (result.next()) {
				Incident incident = new Incident();
				incident.setIncidentId(result.getLong("incident_id"));
				incident.setAssetId(result.getLong("asset_id"));
				incident.setAssetUsageId(nullableLong(result, "asset_usage_id"));
				incident.setAssetItemId(nullableLong(result, "asset_item_id"));
				incident.setInspectionItemId(nullableLong(result, "inspection_item_id"));
				incident.setReportedBy(result.getLong("reported_by"));
				incident.setAffectedQuantity(result.getInt("affected_quantity"));
				incident.setIncidentType(result.getString("incident_type"));
				incident.setDescription(result.getString("description"));
				incident.setSeverity(result.getString("severity"));
				incident.setStatus(result.getString("status"));
				incident.setOccurredAt(ViewFormat.fromUtc(result.getTimestamp("occurred_at")));
				incident.setReportedAt(ViewFormat.fromUtc(result.getTimestamp("reported_at")));
				incident.setInvestigationNote(result.getString("investigation_note"));
				incident.setHandlingResult(result.getString("handling_result"));
				incident.setReportedCause(result.getString("reported_cause"));
				incident.setDeterminedCause(result.getString("determined_cause"));
				incident.setCreatedAt(ViewFormat.fromUtc(result.getTimestamp("created_at")));
				incident.setUpdatedAt(ViewFormat.fromUtc(result.getTimestamp("updated_at")));
				incident.setAssetCode(result.getString("asset_code"));
				incident.setAssetName(result.getString("asset_name"));
				incident.setAssetItemCode(result.getString("asset_item_code"));
				incident.setReporterName(result.getString("reporter_name"));
				incident.setInternCode(result.getString("intern_code"));
				incident.setInternName(result.getString("intern_name"));
				incidents.add(incident);
			}
			return incidents;
		}
	}

	private Long nullableLong(ResultSet result, String column) throws SQLException {
		long value = result.getLong(column);
		return result.wasNull() ? null : value;
	}
}
