package fpt.swp391.labtoolequip.dao;

import fpt.swp391.labtoolequip.common.DBConnection;
import fpt.swp391.labtoolequip.model.PasswordResetRequest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class PasswordResetRequestDAO {
	private final DBConnection db = new DBConnection();

	public void create(String email, String note) throws SQLException {
		String sql = """
				INSERT dbo.password_reset_requests(target_user_id, request_note)
				SELECT u.user_id, ? FROM dbo.users u
				WHERE LOWER(u.email)=LOWER(?)
				AND u.role IN ('MENTOR','LAB_MANAGER') AND u.status='ACTIVE'
				AND NOT EXISTS (
					SELECT 1 FROM dbo.password_reset_requests r WITH (UPDLOCK,HOLDLOCK)
					WHERE r.target_user_id=u.user_id AND r.status IN ('PENDING','APPROVED','ISSUED')
				)
				""";
		try (Connection c = db.getConnection(); PreparedStatement s = c.prepareStatement(sql)) {
			s.setString(1, blank(note));
			s.setString(2, email);
			try {
				s.executeUpdate();
			} catch (SQLException exception) {
				if (exception.getErrorCode() != 2601 && exception.getErrorCode() != 2627)
					throw exception;
			}
		}
	}

	public int countPending() throws SQLException {
		try (Connection c = db.getConnection();
				PreparedStatement s = c
						.prepareStatement("SELECT COUNT(*) FROM dbo.password_reset_requests WHERE status='PENDING'");
				ResultSet r = s.executeQuery()) {
			r.next();
			return r.getInt(1);
		}
	}

	public List<PasswordResetRequest> findAll() throws SQLException {
		String sql = """
				SELECT r.*,u.full_name,u.email,u.role FROM dbo.password_reset_requests r
				JOIN dbo.users u ON u.user_id=r.target_user_id ORDER BY r.created_at DESC
				""";
		try (Connection c = db.getConnection();
				PreparedStatement s = c.prepareStatement(sql);
				ResultSet r = s.executeQuery()) {
			List<PasswordResetRequest> out = new ArrayList<>();
			while (r.next())
				out.add(new PasswordResetRequest(r.getLong("reset_request_id"), r.getLong("target_user_id"),
						r.getString("full_name"), r.getString("email"), r.getString("role"), r.getString("status"),
						r.getString("request_note"), r.getString("review_note"),
						r.getTimestamp("created_at").toLocalDateTime()));
			return out;
		}
	}

	public void review(long id, long adminId, boolean approve, String note) throws SQLException {
		String sql = "UPDATE dbo.password_reset_requests SET status=?,reviewed_by=?,reviewed_at=SYSUTCDATETIME(),review_note=?,updated_at=SYSUTCDATETIME() WHERE reset_request_id=? AND status='PENDING'";
		try (Connection c = db.getConnection(); PreparedStatement s = c.prepareStatement(sql)) {
			s.setString(1, approve ? "APPROVED" : "REJECTED");
			s.setLong(2, adminId);
			s.setString(3, blank(note));
			s.setLong(4, id);
			if (s.executeUpdate() != 1)
				throw new IllegalStateException("Only pending requests can be reviewed.");
		}
	}

	public void issue(long id, long adminId, String hash) throws SQLException {
		try (Connection c = db.getConnection()) {
			c.setAutoCommit(false);
			try {
				long userId;
				try (PreparedStatement s = c.prepareStatement(
						"SELECT target_user_id FROM dbo.password_reset_requests WITH (UPDLOCK,HOLDLOCK) WHERE reset_request_id=? AND status='APPROVED' AND reviewed_by=?")) {
					s.setLong(1, id);
					s.setLong(2, adminId);
					try (ResultSet r = s.executeQuery()) {
						if (!r.next())
							throw new IllegalStateException("Request must be approved first.");
						userId = r.getLong(1);
					}
				}
				try (PreparedStatement s = c.prepareStatement(
						"UPDATE dbo.users SET password_hash=?,must_change_password=1,password_expires_at=DATEADD(hour,24,SYSUTCDATETIME()),updated_at=SYSUTCDATETIME() WHERE user_id=?")) {
					s.setString(1, hash);
					s.setLong(2, userId);
					s.executeUpdate();
				}
				try (PreparedStatement s = c.prepareStatement(
						"UPDATE dbo.password_reset_requests SET status='ISSUED',issued_at=SYSUTCDATETIME(),updated_at=SYSUTCDATETIME() WHERE reset_request_id=?")) {
					s.setLong(1, id);
					s.executeUpdate();
				}
				c.commit();
			} catch (SQLException | RuntimeException e) {
				c.rollback();
				throw e;
			}
		}
	}

	public void consumeIssued(long userId) throws SQLException {
		try (Connection c = db.getConnection();
				PreparedStatement s = c.prepareStatement(
						"UPDATE dbo.password_reset_requests SET status='CONSUMED',consumed_at=SYSUTCDATETIME(),updated_at=SYSUTCDATETIME() WHERE target_user_id=? AND status='ISSUED'")) {
			s.setLong(1, userId);
			s.executeUpdate();
		}
	}

	private String blank(String value) {
		return value == null || value.isBlank() ? null : value.trim();
	}
}
