import { Controller } from "@hotwired/stimulus"
import GameChannel from "channels/game_channel"

export default class extends Controller {
  static targets = ["canvas", "toolbar", "drawerWord", "guesserWord"]
  static values = {
    drawerId: Number,
    roomId: Number,
    turnId: Number
  }

  connect() {
    this.canvas = this.canvasTarget
    console.log("Canvas element:", this.canvasTarget)
    this.ctx = this.canvas.getContext("2d")
    this.isDrawing = false
    this.currentColor = "#000000"
    this.currentSize = 4
    this.tool = "pencil"
    this.lastX = 0
    this.lastY = 0
    this.throttleTimer = null

    // figure out if current user is drawer from the page
    const currentUserId = parseInt(document.querySelector('meta[name="current-user-id"]')?.content)
    this.isDrawer = currentUserId === this.drawerIdValue

    console.log("Canvas connected")
    console.log("Current user ID:", currentUserId)
    console.log("Drawer ID:", this.drawerIdValue)
    console.log("Is drawer:", currentUserId === this.drawerIdValue)

    this.resizeCanvas()
    this.subscribeToChannel()
    this.setUpUI()
  }

  disconnect() {
    clearTimeout(this.throttleTimer)
  }

  setUpUI() {
    if (this.isDrawer) {
      // show drawer word in header
      const wordBlanks = document.getElementById("word-blanks")
      const wordActual = document.getElementById("word-actual")
      if (wordBlanks) wordBlanks.classList.add("hidden")
      if (wordActual) wordActual.classList.remove("hidden")
  
      // show drawer tools in canvas area
      if (this.hasToolbarTarget) this.toolbarTarget.classList.remove("hidden")
      this.canvas.style.cursor = "crosshair"
      this.setupDrawingEvents()
    } else {
      // show guesser UI
      this.canvas.style.cursor = "default"
      this.canvas.style.pointerEvents = "none"
    }
  }

  resizeCanvas() {
    const rect = this.canvas.parentElement.getBoundingClientRect()
    this.canvas.width = rect.width
    this.canvas.height = rect.height
  }

  subscribeToChannel() {
    GameChannel.subscribe(this.roomIdValue)
    GameChannel.on("stroke", (data) => {
      this.drawStroke(data)
    })
    GameChannel.on("clear", () => this.clearCanvas())
  }

  setupDrawingEvents() {
    this.canvas.addEventListener("mousedown", (e) => this.startDrawing(e))
    this.canvas.addEventListener("mousemove", (e) => this.draw(e))
    this.canvas.addEventListener("mouseup", () => this.stopDrawing())
    this.canvas.addEventListener("mouseleave", () => this.stopDrawing())
  }

  startDrawing(e) {
    this.isDrawing = true
    const pos = this.getPosition(e)
    this.lastX = pos.x
    this.lastY = pos.y
  }

  draw(e) {
    if (!this.isDrawing) return

    const pos = this.getPosition(e)

    this.drawStroke({
      x1: this.lastX,
      y1: this.lastY,
      x2: pos.x,
      y2: pos.y,
      color: this.currentColor,
      size: this.currentSize,
      tool: this.tool
    })

    // throttle broadcast to every 100ms
    if (!this.throttleTimer) {
      this.throttleTimer = setTimeout(() => {
        this.broadcastStroke({
          type: "stroke",
          x1: this.lastX,
          y1: this.lastY,
          x2: pos.x,
          y2: pos.y,
          color: this.currentColor,
          size: this.currentSize,
          tool: this.tool,
          room_id: this.roomIdValue,
          canvas_width: this.canvas.width,
          canvas_height: this.canvas.height
        })
        this.throttleTimer = null
      }, 50)
    }

    this.lastX = pos.x
    this.lastY = pos.y
  }

  stopDrawing() {
    this.isDrawing = false
  }

  drawStroke(data) {
    const ctx = this.ctx

    // normalize coordinates to handle different screen sizes
    const scaleX = this.canvas.width / (data.canvas_width || this.canvas.width)
    const scaleY = this.canvas.height / (data.canvas_height || this.canvas.height)

    ctx.beginPath()
    ctx.moveTo(data.x1 * scaleX, data.y1 * scaleY)
    ctx.lineTo(data.x2 * scaleX, data.y2 * scaleY)
    ctx.strokeStyle = data.tool === "eraser" ? "#ffffff" : data.color
    ctx.lineWidth = data.size
    ctx.lineCap = "round"
    ctx.lineJoin = "round"
    ctx.stroke()
  }

  broadcastStroke(data) {
    GameChannel.perform("draw", data)
  }

  clearCanvas() {
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)
  }

  broadcastClear() {
    GameChannel.perform("draw", {
      type: "clear",
      room_id: this.roomIdValue
    })
  }

  getPosition(e) {
    const rect = this.canvas.getBoundingClientRect()
    return {
      x: e.clientX - rect.left,
      y: e.clientY - rect.top
    }
  }

  setColor(e) {
    this.currentColor = e.currentTarget.dataset.color
  }
  
  setPencil() {
    this.tool = "pencil"
  }
  
  setEraser() {
    this.tool = "eraser"
    this.currentColor = "#ffffff"
  }

  setSize(e) {
    this.currentSize = parseInt(e.currentTarget.dataset.size)
  }
  
  clear(e) {
    e.preventDefault()
    this.clearCanvas()
    this.broadcastClear()
  }
}