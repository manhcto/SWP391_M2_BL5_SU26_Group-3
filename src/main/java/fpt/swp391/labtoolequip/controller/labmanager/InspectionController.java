package fpt.swp391.labtoolequip.controller.labmanager;

import fpt.swp391.labtoolequip.controller.InspectionControllerSupport;
import jakarta.servlet.annotation.WebServlet;

@WebServlet("/lab-manager/inspections/*")
public class InspectionController extends InspectionControllerSupport {
	@Override
	protected String roleBase() {
		return "/lab-manager";
	}

	@Override
	protected String roleName() {
		return "Lab Manager";
	}
}
