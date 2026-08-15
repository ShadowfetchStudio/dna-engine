import AppKit

let size = 1024
let output = CommandLine.arguments.dropFirst().first ?? "icon-1024.png"
let image = NSImage(size: NSSize(width: size, height: size))

image.lockFocus()
let rect = NSRect(x: 0, y: 0, width: size, height: size)

NSColor(red: 0.027, green: 0.043, blue: 0.063, alpha: 1).setFill()
rect.fill()

let glow = NSBezierPath(ovalIn: NSRect(x: 160, y: 200, width: 700, height: 700))
NSColor(red: 0.24, green: 0.88, blue: 0.78, alpha: 0.16).setFill()
glow.fill()

let card = NSBezierPath(roundedRect: NSRect(x: 140, y: 140, width: 744, height: 744), xRadius: 180, yRadius: 180)
NSColor(red: 0.07, green: 0.10, blue: 0.14, alpha: 1).setFill()
card.fill()
NSColor(red: 0.24, green: 0.88, blue: 0.78, alpha: 0.55).setStroke()
card.lineWidth = 14
card.stroke()

func helix() {
    let cx: CGFloat = 512
    for i in 0..<28 {
        let t = CGFloat(i) / 27.0
        let y: CGFloat = 230 + t * 560
        let phase = t * 4.8 * .pi
        let amp: CGFloat = 150
        let x1 = cx + cos(phase) * amp
        let x2 = cx + cos(phase + .pi) * amp
        let rung = NSBezierPath()
        rung.move(to: NSPoint(x: x1, y: y))
        rung.line(to: NSPoint(x: x2, y: y))
        NSColor(red: 0.84, green: 0.66, blue: 0.38, alpha: 0.45).setStroke()
        rung.lineWidth = 8
        rung.lineCapStyle = .round
        rung.stroke()

        let a = NSBezierPath(ovalIn: NSRect(x: x1 - 16, y: y - 16, width: 32, height: 32))
        NSColor(red: 0.24, green: 0.88, blue: 0.78, alpha: 1).setFill()
        a.fill()
        let b = NSBezierPath(ovalIn: NSRect(x: x2 - 16, y: y - 16, width: 32, height: 32))
        NSColor(red: 0.90, green: 0.42, blue: 0.62, alpha: 1).setFill()
        b.fill()
    }
}

helix()
image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fputs("icon render failed\n", stderr)
    exit(1)
}
try png.write(to: URL(fileURLWithPath: output))
print("wrote \(output)")
