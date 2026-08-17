package fpt.swp391.labtoolequip.controller.mentor;

import fpt.swp391.labtoolequip.controller.InspectionControllerSupport;
import jakarta.servlet.annotation.WebServlet;

@WebServlet("/mentor/inspections/*")
public class InspectionController extends InspectionControllerSupport {
	@Override
	protected String roleBase() {
		return "/mentor";
	}

	@Override
	protected String roleName() {
		return "Mentor";
	}
}
