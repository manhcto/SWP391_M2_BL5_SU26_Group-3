package fpt.swp391.labtoolequip.model;

import java.time.LocalDate;

public class EquipmentActivity {
	private Long activityId;
	private Long internListId;
	private Long mentorId;
	private String activityName;
	private String description;
	private LocalDate startDate;
	private LocalDate endDate;
	private String status;
	private String semesterCode;
	private String internListName;

	public Long getActivityId() {
		return activityId;
	}
	public void setActivityId(Long activityId) {
		this.activityId = activityId;
	}
	public Long getInternListId() {
		return internListId;
	}
	public void setInternListId(Long internListId) {
		this.internListId = internListId;
	}
	public Long getMentorId() {
		return mentorId;
	}
	public void setMentorId(Long mentorId) {
		this.mentorId = mentorId;
	}
	public String getActivityName() {
		return activityName;
	}
	public void setActivityName(String activityName) {
		this.activityName = activityName;
	}
	public String getDescription() {
		return description;
	}
	public void setDescription(String description) {
		this.description = description;
	}
	public LocalDate getStartDate() {
		return startDate;
	}
	public void setStartDate(LocalDate startDate) {
		this.startDate = startDate;
	}
	public LocalDate getEndDate() {
		return endDate;
	}
	public void setEndDate(LocalDate endDate) {
		this.endDate = endDate;
	}
	public String getStatus() {
		return status;
	}
	public void setStatus(String status) {
		this.status = status;
	}
	public String getSemesterCode() {
		return semesterCode;
	}
	public void setSemesterCode(String semesterCode) {
		this.semesterCode = semesterCode;
	}
	public String getInternListName() {
		return internListName;
	}
	public void setInternListName(String internListName) {
		this.internListName = internListName;
	}
}
