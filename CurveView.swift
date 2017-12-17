//
//  CurveView.swift
//  DrawPen
//
//  Created by Svyatoshenko "Megal" Misha on 2017-03-08.
//  Copyright © 2017 Megal. All rights reserved.
//

import Cocoa

// MARK: - Dot Transform operation
precedencegroup DotOperationPrecedence {
	higherThan: MultiplicationPrecedence
	assignment: true
}
infix operator .--> : DotOperationPrecedence
public func .--> <U, V>(arg: U, transform: (U) -> V ) -> V {
	return transform(arg)
}


@IBDesignable
public class CurveView: NSView {

	var editingEvent = 0
	var brushSize: CGFloat = 20.0
	typealias Joint = (point: NSPoint, radius: CGFloat)
	var joints: [Joint] = []
	var drawnBuffer: [[Joint]] = []

	//MARK: - Pen/Mouse events

	public override var mouseDownCanMoveWindow: Bool { return false }


	public override func mouseDown(with event: NSEvent) {
		if editingEvent == 0 {
			editingEvent = event.eventNumber
		}
	}

	public override func mouseDragged(with event: NSEvent) {

		guard event.eventNumber == editingEvent else { return }

		let point = self.convert(event.locationInWindow, from: nil)
		let radius = brushSize * CGFloat(event.pressure)

		joints.append((point: point, radius: radius))
	}

	public override func mouseUp(with event: NSEvent) {

		guard event.eventNumber == editingEvent else { return }
		defer {
			editingEvent = 0
		}

		if drawnBuffer.count > 10 {
			drawnBuffer.removeAll()
		}
		drawnBuffer.append(joints)

		joints.removeAll()
		self.setNeedsDisplay(self.frame)
	}


	// MARK: - Drawing

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

		for drawn in drawnBuffer {
			// ---
			// Fill centers with red
			// ---
			NSColor.red.setFill()
			for (point, radius) in drawn {
				NSBezierPath(ovalIn: NSRect(x: point.x-radius, y: point.y-radius, width: 2.0*radius, height: 2.0*radius)).fill()
			}

			// ---
			// Draw central line
			// ---
			NSColor.blue.setStroke()
			makeBezierPath(with: drawn.map{$0.point}).stroke()

			// ---
			// Draw lateral lines
			// ---
			let bezier = makeLateralBezierCurves(drawn)
			NSColor.black.setStroke()
			bezier.stroke()
		}
    }
}
