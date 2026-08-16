package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.model.MaintenanceRecord;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class MaintenanceDAO {
	private static final String SELECT_BASE = """
			SELECT m.maintenance_id, m.asset_id, m.incident_id, m.quantity, m.requested_by,
			       m.description, m.requested_at, m.status, m.approved_by, m.approved_at,
			       m.approval_note, m.repair_started_at, m.repair_completed_at,
			       m.repair_result, m.note, m.created_at, m.updated_at,
			       a.asset_name, a.asset_code,
			       u_req.full_name AS requester_name,
			       u_app.full_name AS approver_name
			FROM dbo.maintenance_records m
			JOIN dbo.assets a ON a.asset_id = m.asset_id
			JOIN dbo.users u_req ON u_req.user_id = m.requested_by
			LEFT JOIN dbo.users u_app ON u_app.user_id = m.approved_by
			""";

	private final DBConnection dbConnection = new DBConnection();

	public List<MaintenanceRecord> findAll(String keyword, String status, Long assetId) throws SQLException {
		StringBuilder sql = new StringBuilder(SELECT_BASE);
		sql.append(" WHERE 1=1 ");

		String search = keyword == null ? "" : keyword.trim();
		String statusFilter = status == null ? "" : status.trim();

		if (!search.isEmpty()) {
			sql.append(" AND (a.asset_name LIKE ? OR a.asset_code LIKE ? OR m.description LIKE ?) ");
		}
		if (!statusFilter.isEmpty()) {
			sql.append(" AND m.status = ? ");
		}
		if (assetId != null && assetId > 0) {
			sql.append(" AND m.asset_id = ? ");
		}

		sql.append(" ORDER BY m.created_at DESC, m.maintenance_id DESC ");

		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql.toString())) {
			int idx = 1;
			if (!search.isEmpty()) {
				statement.setString(idx++, "%" + search + "%");
				statement.setString(idx++, "%" + search + "%");
				statement.setString(idx++, "%" + search + "%");
			}
			if (!statusFilter.isEmpty()) {
				statement.setString(idx++, statusFilter);
			}
			if (assetId != null && assetId > 0) {
				statement.setLong(idx++, assetId);
			}

			try (ResultSet rs = statement.executeQuery()) {
				List<MaintenanceRecord> list = new ArrayList<>();
				while (rs.next()) {
					list.add(mapRecord(rs));
				}
				return list;
			}
		}
	}

	public List<MaintenanceRecord> findByRequester(long requestedBy, String keyword, String status)
			throws SQLException {
		StringBuilder sql = new StringBuilder(SELECT_BASE);
		sql.append(" WHERE m.requested_by = ? ");

		String search = keyword == null ? "" : keyword.trim();
		String statusFilter = status == null ? "" : status.trim();

		if (!search.isEmpty()) {
			sql.append(" AND (a.asset_name LIKE ? OR a.asset_code LIKE ? OR m.description LIKE ?) ");
		}
		if (!statusFilter.isEmpty()) {
			sql.append(" AND m.status = ? ");
		}

		sql.append(" ORDER BY m.created_at DESC, m.maintenance_id DESC ");

		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql.toString())) {
			int idx = 1;
			statement.setLong(idx++, requestedBy);
			if (!search.isEmpty()) {
				statement.setString(idx++, "%" + search + "%");
				statement.setString(idx++, "%" + search + "%");
				statement.setString(idx++, "%" + search + "%");
			}
			if (!statusFilter.isEmpty()) {
				statement.setString(idx++, statusFilter);
			}

			try (ResultSet rs = statement.executeQuery()) {
				List<MaintenanceRecord> list = new ArrayList<>();
				while (rs.next()) {
					list.add(mapRecord(rs));
				}
				return list;
			}
		}
	}

	public Optional<MaintenanceRecord> findById(long maintenanceId) throws SQLException {
		String sql = SELECT_BASE + " WHERE m.maintenance_id = ? ";
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setLong(1, maintenanceId);
			try (ResultSet rs = statement.executeQuery()) {
				if (rs.next()) {
					return Optional.of(mapRecord(rs));
				}
				return Optional.empty();
			}
		}
	}

	public long create(MaintenanceRecord record) throws SQLException {
		String sql = """
				INSERT INTO dbo.maintenance_records (asset_id, incident_id, quantity, requested_by, description, status)
				VALUES (?, ?, ?, ?, ?, 'PENDING')
				""";
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
			statement.setLong(1, record.getAssetId());
			if (record.getIncidentId() != null && record.getIncidentId() > 0) {
				statement.setLong(2, record.getIncidentId());
			} else {
				statement.setNull(2, java.sql.Types.BIGINT);
			}
			statement.setInt(3, record.getQuantity() != null ? record.getQuantity() : 1);
			statement.setLong(4, record.getRequestedBy());
			statement.setString(5, record.getDescription());

			statement.executeUpdate();
			try (ResultSet keys = statement.getGeneratedKeys()) {
				if (keys.next()) {
					return keys.getLong(1);
				}
				throw new SQLException("Creating maintenance record failed: no ID generated.");
			}
		}
	}

	public boolean approveOrReject(long maintenanceId, String status, long approvedBy, String approvalNote)
			throws SQLException {
		String sql = """
				UPDATE dbo.maintenance_records
				SET status = ?,
				    approved_by = ?,
				    approved_at = SYSUTCDATETIME(),
				    approval_note = ?,
				    updated_at = SYSUTCDATETIME()
				WHERE maintenance_id = ?
				""";
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, status);
			statement.setLong(2, approvedBy);
			statement.setString(3, approvalNote);
			statement.setLong(4, maintenanceId);
			return statement.executeUpdate() == 1;
		}
	}

	public boolean updateProgress(long maintenanceId, String status, LocalDateTime startedAt, LocalDateTime completedAt,
			String repairResult, String note) throws SQLException {
		String sql = """
				UPDATE dbo.maintenance_records
				SET status = ?,
				    repair_started_at = ?,
				    repair_completed_at = ?,
				    repair_result = ?,
				    note = ?,
				    updated_at = SYSUTCDATETIME()
				WHERE maintenance_id = ?
				""";
		try (Connection connection = dbConnection.getConnection();
				PreparedStatement statement = connection.prepareStatement(sql)) {
			statement.setString(1, status);
			statement.setTimestamp(2, startedAt != null ? Timestamp.valueOf(startedAt) : null);
			statement.setTimestamp(3, completedAt != null ? Timestamp.valueOf(completedAt) : null);
			statement.setString(4, repairResult);
			statement.setString(5, note);
			statement.setLong(6, maintenanceId);
			return statement.executeUpdate() == 1;
		}
	}

	private MaintenanceRecord mapRecord(ResultSet rs) throws SQLException {
		MaintenanceRecord m = new MaintenanceRecord();
		m.setMaintenanceId(rs.getLong("maintenance_id"));
		m.setAssetId(rs.getLong("asset_id"));
		long incId = rs.getLong("incident_id");
		m.setIncidentId(rs.wasNull() ? null : incId);
		m.setQuantity(rs.getInt("quantity"));
		m.setRequestedBy(rs.getLong("requested_by"));
		m.setDescription(rs.getString("description"));
		m.setRequestedAt(toLocalDateTime(rs.getTimestamp("requested_at")));
		m.setStatus(rs.getString("status"));
		long appBy = rs.getLong("approved_by");
		m.setApprovedBy(rs.wasNull() ? null : appBy);
		m.setApprovedAt(toLocalDateTime(rs.getTimestamp("approved_at")));
		m.setApprovalNote(rs.getString("approval_note"));
		m.setRepairStartedAt(toLocalDateTime(rs.getTimestamp("repair_started_at")));
		m.setRepairCompletedAt(toLocalDateTime(rs.getTimestamp("repair_completed_at")));
		m.setRepairResult(rs.getString("repair_result"));
		m.setNote(rs.getString("note"));
		m.setCreatedAt(toLocalDateTime(rs.getTimestamp("created_at")));
		m.setUpdatedAt(toLocalDateTime(rs.getTimestamp("updated_at")));

		m.setAssetName(rs.getString("asset_name"));
		m.setAssetCode(rs.getString("asset_code"));
		m.setRequesterName(rs.getString("requester_name"));
		m.setApproverName(rs.getString("approver_name"));
		return m;
	}

	private LocalDateTime toLocalDateTime(Timestamp timestamp) {
		return timestamp == null ? null : timestamp.toLocalDateTime();
	}
}
