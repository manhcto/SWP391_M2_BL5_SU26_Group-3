package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;

public class Responsibility {
	private Long responsibilityId;
	private Long incidentId;
	private Long internId;
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
	private String internCode;
	private String internName;
	private String internEmail;
	private String mentorName;
	private String reviewerName;
	private String incidentType;
	private String incidentDescription;
	private String incidentSeverity;
	private String incidentStatus;
	private String investigationNote;
	private String handlingResult;
	private LocalDateTime occurredAt;
	private LocalDateTime reportedAt;
	private Long assetId;
	private String assetCode;
	private String assetName;
	private Long assetUsageId;
	private String usageStatus;
	private LocalDateTime borrowedAt;
	private LocalDateTime dueAt;
	private LocalDateTime returnedAt;

	public Responsibility() {
	}

	public String getResponsibilityCode() {
		if (responsibilityId == null)
			return "";
		return determinedAt == null
				? "RES-" + responsibilityId
				: "RES-%d-%03d".formatted(determinedAt.getYear(), responsibilityId);
	}

	public String getIncidentCode() {
		if (incidentId == null)
			return "";
		return reportedAt == null ? "INC-" + incidentId : "INC-%d-%03d".formatted(reportedAt.getYear(), incidentId);
	}

	public Long getResponsibilityId() {
		return responsibilityId;
	}
	public void setResponsibilityId(Long value) {
		responsibilityId = value;
	}
	public Long getIncidentId() {
		return incidentId;
	}
	public void setIncidentId(Long value) {
		incidentId = value;
	}
	public Long getInternId() {
		return internId;
	}
	public void setInternId(Long value) {
		internId = value;
	}
	public Long getDeterminedBy() {
		return determinedBy;
	}
	public void setDeterminedBy(Long value) {
		determinedBy = value;
	}
	public String getConclusion() {
		return conclusion;
	}
	public void setConclusion(String value) {
		conclusion = value;
	}
	public String getDecision() {
		return decision;
	}
	public void setDecision(String value) {
		decision = value;
	}
	public String getStatus() {
		return status;
	}
	public void setStatus(String value) {
		status = value;
	}
	public Long getReviewedBy() {
		return reviewedBy;
	}
	public void setReviewedBy(Long value) {
		reviewedBy = value;
	}
	public LocalDateTime getReviewedAt() {
		return reviewedAt;
	}
	public void setReviewedAt(LocalDateTime value) {
		reviewedAt = value;
	}
	public String getReviewNote() {
		return reviewNote;
	}
	public void setReviewNote(String value) {
		reviewNote = value;
	}
	public String getResolutionNote() {
		return resolutionNote;
	}
	public void setResolutionNote(String value) {
		resolutionNote = value;
	}
	public LocalDateTime getDeterminedAt() {
		return determinedAt;
	}
	public void setDeterminedAt(LocalDateTime value) {
		determinedAt = value;
	}
	public LocalDateTime getResolvedAt() {
		return resolvedAt;
	}
	public void setResolvedAt(LocalDateTime value) {
		resolvedAt = value;
	}
	public LocalDateTime getCreatedAt() {
		return createdAt;
	}
	public void setCreatedAt(LocalDateTime value) {
		createdAt = value;
	}
	public LocalDateTime getUpdatedAt() {
		return updatedAt;
	}
	public void setUpdatedAt(LocalDateTime value) {
		updatedAt = value;
	}
	public String getInternCode() {
		return internCode;
	}
	public void setInternCode(String value) {
		internCode = value;
	}
	public String getInternName() {
		return internName;
	}
	public void setInternName(String value) {
		internName = value;
	}
	public String getInternEmail() {
		return internEmail;
	}
	public void setInternEmail(String value) {
		internEmail = value;
	}
	public String getMentorName() {
		return mentorName;
	}
	public void setMentorName(String value) {
		mentorName = value;
	}
	public String getReviewerName() {
		return reviewerName;
	}
	public void setReviewerName(String value) {
		reviewerName = value;
	}
	public String getIncidentType() {
		return incidentType;
	}
	public void setIncidentType(String value) {
		incidentType = value;
	}
	public String getIncidentDescription() {
		return incidentDescription;
	}
	public void setIncidentDescription(String value) {
		incidentDescription = value;
	}
	public String getIncidentSeverity() {
		return incidentSeverity;
	}
	public void setIncidentSeverity(String value) {
		incidentSeverity = value;
	}
	public String getIncidentStatus() {
		return incidentStatus;
	}
	public void setIncidentStatus(String value) {
		incidentStatus = value;
	}
	public String getInvestigationNote() {
		return investigationNote;
	}
	public void setInvestigationNote(String value) {
		investigationNote = value;
	}
	public String getHandlingResult() {
		return handlingResult;
	}
	public void setHandlingResult(String value) {
		handlingResult = value;
	}
	public LocalDateTime getOccurredAt() {
		return occurredAt;
	}
	public void setOccurredAt(LocalDateTime value) {
		occurredAt = value;
	}
	public LocalDateTime getReportedAt() {
		return reportedAt;
	}
	public void setReportedAt(LocalDateTime value) {
		reportedAt = value;
	}
	public Long getAssetId() {
		return assetId;
	}
	public void setAssetId(Long value) {
		assetId = value;
	}
	public String getAssetCode() {
		return assetCode;
	}
	public void setAssetCode(String value) {
		assetCode = value;
	}
	public String getAssetName() {
		return assetName;
	}
	public void setAssetName(String value) {
		assetName = value;
	}
	public Long getAssetUsageId() {
		return assetUsageId;
	}
	public void setAssetUsageId(Long value) {
		assetUsageId = value;
	}
	public String getUsageStatus() {
		return usageStatus;
	}
	public void setUsageStatus(String value) {
		usageStatus = value;
	}
	public LocalDateTime getBorrowedAt() {
		return borrowedAt;
	}
	public void setBorrowedAt(LocalDateTime value) {
		borrowedAt = value;
	}
	public LocalDateTime getDueAt() {
		return dueAt;
	}
	public void setDueAt(LocalDateTime value) {
		dueAt = value;
	}
	public LocalDateTime getReturnedAt() {
		return returnedAt;
	}
	public void setReturnedAt(LocalDateTime value) {
		returnedAt = value;
	}
}
