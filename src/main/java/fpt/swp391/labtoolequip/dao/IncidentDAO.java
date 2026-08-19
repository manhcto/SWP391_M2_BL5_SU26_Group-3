package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.common.ViewFormat;
import fpt.swp391.labtoolequip.model.Incident;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class IncidentDAO {
	private static final String SELECT = """
			SELECT i.*, a.asset_code, a.asset_name, reporter.full_name AS reporter_name,
			       au.asset_item_id, ai.item_code AS asset_item_code,
			       sp.student_code AS intern_code, intern.full_name AS intern_name
			FROM dbo.incidents i
			JOIN dbo.assets a ON a.asset_id = i.asset_id
			JOIN dbo.users reporter ON reporter.user_id = i.reported_by
			LEFT JOIN dbo.asset_usages au ON au.asset_usage_id = i.asset_usage_id
			LEFT JOIN dbo.asset_items ai ON ai.asset_item_id = au.asset_item_id
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
				ORDER BY COALESCE(i.occurred_at, i.reported_at) DESC, i.incident_id DESC
				""";
		try (Connection connection = db.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
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
