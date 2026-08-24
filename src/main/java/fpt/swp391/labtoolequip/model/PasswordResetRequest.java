package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;

public record PasswordResetRequest(long id, long userId, String userName, String email, String role, String status,
		String requestNote, String reviewNote, LocalDateTime createdAt) {
}
