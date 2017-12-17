//
//  Curves.swift
//  DrawPen
//
//  Created by Svyatoshenko "Megal" Misha on 2017-03-08.
//  Copyright © 2017 Megal. All rights reserved.
//

import Foundation
import AppKit

//// MARK: - Cartesian 2d
//typealias Int2d = (x: Int, y: Int)
//func +(a: Int2d, b: Int2d) -> Int2d { return (a.x+b.x, a.y+b.y) }
//func -(a: Int2d, b: Int2d) -> Int2d { return (a.x-b.x, a.y-b.y) }

func +(a: NSPoint, b: NSPoint) -> NSPoint { return NSPoint(x: a.x+b.x, y: a.y+b.y) }
func -(a: NSPoint, b: NSPoint) -> NSPoint { return NSPoint(x: a.x-b.x, y: a.y-b.y) }
func *(vec: NSPoint, scalar: CGFloat) -> NSPoint { return NSPoint(x: vec.x*scalar, y: vec.y*scalar) }

extension NSPoint {

	var length: CGFloat {

		return sqrt(x * x + y * y)
	}

	var norm: NSPoint? {

		let length = self.length

		guard length > 1e-9 else { return nil }
		return NSPoint(x: x/length, y: y/length)
	}
}


typealias Joint = (point: NSPoint, radius: CGFloat)

struct Vertex {
	var origin: NSPoint
	var leftControlPoint: NSPoint
	var rightControlPoint: NSPoint
	var ortCW: NSPoint
}

func vertexArray(with points: [NSPoint]) -> [Vertex] {

	guard case let N = points.count, N > 1 else { return [] }

	var vertexes: [Vertex] = []
	for i in points.indices {
		let left = max(0, i-1)
		let right = min(i+1, N-1)

		let a = points[i] - points[left]
		let anorm = a.norm ?? a

		let b = points[right] - points[i]
		let bnorm = b.norm ?? b

		let tangent = anorm+bnorm
		let ortCW = NSPoint(x: tangent.y, y: -tangent.x).norm ?? .zero

		let nexVertex = Vertex(
			origin: points[i],
			leftControlPoint: points[i] - tangent*(a.length/6.0),
			rightControlPoint: points[i] + tangent*(b.length/6.0),
			ortCW:ortCW)
		vertexes.append(nexVertex)
	}

	return vertexes
}

func makeBezierPath(with points: [NSPoint]) -> NSBezierPath {

	var path = NSBezierPath()
	guard case let N = points.count, N > 1 else { return path }

	let vertexes = vertexArray(with: points)
	path.move(to: vertexes[0].origin)

	let segments = zip(vertexes.prefix(N-1), vertexes.suffix(N-1))
	for (a, b) in segments {
		path.curve(to: b.origin, controlPoint1: a.rightControlPoint, controlPoint2: b.leftControlPoint)
	}

	return path
}

func makeLateralBezierCurves(_ coordinates: [Joint] ) -> NSBezierPath {

	guard coordinates.count > 1 else { return NSBezierPath(rect: .zero) }
	let N = coordinates.count

	let path = NSBezierPath()
	let points = coordinates.map{$0.point}
	let radii = coordinates.map{$0.radius}

	let vertexes = vertexArray(with: points)

	var rightpath: [NSPoint] = []
	for (i, vertex) in vertexes.enumerated() {
		let p = vertex.origin + vertex.ortCW*coordinates[i].radius
		rightpath.append(p)
	}

	var leftpath: [NSPoint] = []
	for (i, vertex) in vertexes.enumerated().reversed() {
		let p = vertex.origin - vertex.ortCW*coordinates[i].radius
		leftpath.append(p)
	}

	path.append(makeBezierPath(with: rightpath))
	path.append(makeBezierPath(with: leftpath))

//	path.appendArc(withCenter: coordinates[N-1].point, radius: coordinates[N-1].radius, startAngle: 0, endAngle: 180, clockwise: true)
//	path.appendArc(from: rightpath.last!, to: leftpath[0], radius: coordinates[N-1].radius)
//	path.move(to: leftpath[0])
//	path.appendArc(withCenter: coordinates[0].point, radius: coordinates[0].radius, startAngle: 0, endAngle: 180, clockwise: true)
//	path.appendArc(from: leftpath.last!, to: rightpath[0], radius: coordinates[0].radius)
//	path.close()

	return path
}
