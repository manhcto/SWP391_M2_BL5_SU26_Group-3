package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;

public class Responsibility {
	private Long responsibilityId;
	private Long incidentId;
	private Long studentId;
	private Long determinedBy;
	private String conclusion;
	private String decision;
	private String status;
	private Long reviewedBy;
	private LocalDateTime reviewedAt;
	private String reviewNote;
	private String resolutionNote;
	private LocalDateTime determinedAt;
	private LocalDateTime resolvedAt;
	private LocalDateTime createdAt;
	private LocalDateTime updatedAt;

	public Responsibility() {
	}

	public Responsibility(Long responsibilityId, Long incidentId, Long studentId, Long determinedBy, String conclusion,
			String decision, String status, Long reviewedBy, LocalDateTime reviewedAt, String reviewNote,
			String resolutionNote, LocalDateTime determinedAt, LocalDateTime resolvedAt, LocalDateTime createdAt,
			LocalDateTime updatedAt) {
		this.responsibilityId = responsibilityId;
		this.incidentId = incidentId;
		this.studentId = studentId;
		this.determinedBy = determinedBy;
		this.conclusion = conclusion;
		this.decision = decision;
		this.status = status;
		this.reviewedBy = reviewedBy;
		this.reviewedAt = reviewedAt;
		this.reviewNote = reviewNote;
		this.resolutionNote = resolutionNote;
		this.determinedAt = determinedAt;
		this.resolvedAt = resolvedAt;
		this.createdAt = createdAt;
		this.updatedAt = updatedAt;
	}

	public Long getResponsibilityId() {
		return responsibilityId;
	}

	public void setResponsibilityId(Long responsibilityId) {
		this.responsibilityId = responsibilityId;
	}

	public Long getIncidentId() {
		return incidentId;
	}

	public void setIncidentId(Long incidentId) {
		this.incidentId = incidentId;
	}

	public Long getStudentId() {
		return studentId;
	}

	public void setStudentId(Long studentId) {
		this.studentId = studentId;
	}

	public Long getDeterminedBy() {
		return determinedBy;
	}

	public void setDeterminedBy(Long determinedBy) {
		this.determinedBy = determinedBy;
	}

	public String getConclusion() {
		return conclusion;
	}

	public void setConclusion(String conclusion) {
		this.conclusion = conclusion;
	}

	public String getDecision() {
		return decision;
	}

	public void setDecision(String decision) {
		this.decision = decision;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public Long getReviewedBy() {
		return reviewedBy;
	}

	public void setReviewedBy(Long reviewedBy) {
		this.reviewedBy = reviewedBy;
	}

	public LocalDateTime getReviewedAt() {
		return reviewedAt;
	}

	public void setReviewedAt(LocalDateTime reviewedAt) {
		this.reviewedAt = reviewedAt;
	}

	public String getReviewNote() {
		return reviewNote;
	}

	public void setReviewNote(String reviewNote) {
		this.reviewNote = reviewNote;
	}

	public String getResolutionNote() {
		return resolutionNote;
	}

	public void setResolutionNote(String resolutionNote) {
		this.resolutionNote = resolutionNote;
	}

	public LocalDateTime getDeterminedAt() {
		return determinedAt;
	}

	public void setDeterminedAt(LocalDateTime determinedAt) {
		this.determinedAt = determinedAt;
	}

	public LocalDateTime getResolvedAt() {
		return resolvedAt;
	}

	public void setResolvedAt(LocalDateTime resolvedAt) {
		this.resolvedAt = resolvedAt;
	}

	public LocalDateTime getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(LocalDateTime createdAt) {
		this.createdAt = createdAt;
	}

	public LocalDateTime getUpdatedAt() {
		return updatedAt;
	}

	public void setUpdatedAt(LocalDateTime updatedAt) {
		this.updatedAt = updatedAt;
	}
}
