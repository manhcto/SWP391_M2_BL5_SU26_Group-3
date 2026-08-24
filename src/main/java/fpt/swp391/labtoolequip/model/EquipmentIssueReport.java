package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;

public class EquipmentIssueReport {
	private Long issueReportId;
	private Long allocationId;
	private String issueType;
	private String description;
	private String imagePath;
	private String status;
	private String mentorNote;
	private String reporterName;
	private String activityName;
	private String itemCode;
	private LocalDateTime createdAt;

	public Long getIssueReportId() { return issueReportId; }
	public void setIssueReportId(Long issueReportId) { this.issueReportId = issueReportId; }
	public Long getAllocationId() { return allocationId; }
	public void setAllocationId(Long allocationId) { this.allocationId = allocationId; }
	public String getIssueType() { return issueType; }
	public void setIssueType(String issueType) { this.issueType = issueType; }
	public String getDescription() { return description; }
	public void setDescription(String description) { this.description = description; }
	public String getImagePath() { return imagePath; }
	public void setImagePath(String imagePath) { this.imagePath = imagePath; }
	public String getStatus() { return status; }
	public void setStatus(String status) { this.status = status; }
	public String getMentorNote() { return mentorNote; }
	public void setMentorNote(String mentorNote) { this.mentorNote = mentorNote; }
	public String getReporterName() { return reporterName; }
	public void setReporterName(String reporterName) { this.reporterName = reporterName; }
	public String getActivityName() { return activityName; }
	public void setActivityName(String activityName) { this.activityName = activityName; }
	public String getItemCode() { return itemCode; }
	public void setItemCode(String itemCode) { this.itemCode = itemCode; }
	public LocalDateTime getCreatedAt() { return createdAt; }
	public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
