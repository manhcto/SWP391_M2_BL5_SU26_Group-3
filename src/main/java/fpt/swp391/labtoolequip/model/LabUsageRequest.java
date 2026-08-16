package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class LabUsageRequest {
	private Long requestId;
	private Long semesterId;
	private Long mentorId;
	private String groupName;
	private String status;
	private String requestNote;
	private Long approvedBy;
	private LocalDateTime approvedAt;
	private String approvalNote;
	private LocalDateTime createdAt;
	private LocalDateTime updatedAt;
	private String semesterCode;
	private String semesterName;
	private int studentCount;
	private String scheduleSummary;
	private List<LabUsageRequestSlot> slots = new ArrayList<>();
	private List<LabUsageRequestStudent> students = new ArrayList<>();

	public LabUsageRequest() {
	}

	public LabUsageRequest(Long requestId, Long semesterId, Long mentorId, String status, String requestNote,
			Long approvedBy, LocalDateTime approvedAt, String approvalNote, LocalDateTime createdAt,
			LocalDateTime updatedAt) {
		this.requestId = requestId;
		this.semesterId = semesterId;
		this.mentorId = mentorId;
		this.status = status;
		this.requestNote = requestNote;
		this.approvedBy = approvedBy;
		this.approvedAt = approvedAt;
		this.approvalNote = approvalNote;
		this.createdAt = createdAt;
		this.updatedAt = updatedAt;
	}

	public Long getRequestId() {
		return requestId;
	}

	public void setRequestId(Long requestId) {
		this.requestId = requestId;
	}

	public Long getSemesterId() {
		return semesterId;
	}

	public void setSemesterId(Long semesterId) {
		this.semesterId = semesterId;
	}

	public Long getMentorId() {
		return mentorId;
	}

	public void setMentorId(Long mentorId) {
		this.mentorId = mentorId;
	}

	public String getGroupName() {
		return groupName;
	}

	public void setGroupName(String groupName) {
		this.groupName = groupName;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public String getRequestNote() {
		return requestNote;
	}

	public void setRequestNote(String requestNote) {
		this.requestNote = requestNote;
	}

	public Long getApprovedBy() {
		return approvedBy;
	}

	public void setApprovedBy(Long approvedBy) {
		this.approvedBy = approvedBy;
	}

	public LocalDateTime getApprovedAt() {
		return approvedAt;
	}

	public void setApprovedAt(LocalDateTime approvedAt) {
		this.approvedAt = approvedAt;
	}

	public String getApprovalNote() {
		return approvalNote;
	}

	public void setApprovalNote(String approvalNote) {
		this.approvalNote = approvalNote;
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

	public String getSemesterCode() {
		return semesterCode;
	}

	public void setSemesterCode(String semesterCode) {
		this.semesterCode = semesterCode;
	}

	public String getSemesterName() {
		return semesterName;
	}

	public void setSemesterName(String semesterName) {
		this.semesterName = semesterName;
	}

	public int getStudentCount() {
		return studentCount;
	}

	public void setStudentCount(int studentCount) {
		this.studentCount = studentCount;
	}

	public String getScheduleSummary() {
		return scheduleSummary;
	}

	public void setScheduleSummary(String scheduleSummary) {
		this.scheduleSummary = scheduleSummary;
	}

	public List<LabUsageRequestSlot> getSlots() {
		return slots;
	}

	public void setSlots(List<LabUsageRequestSlot> slots) {
		this.slots = slots;
	}

	public List<LabUsageRequestStudent> getStudents() {
		return students;
	}

	public void setStudents(List<LabUsageRequestStudent> students) {
		this.students = students;
	}
}
