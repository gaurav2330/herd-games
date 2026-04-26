// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import TimerController from "controllers/timer_controller"
import CanvasController from "controllers/canvas_controller"
import ChatController from "controllers/chat_controller"
application.register("timer", TimerController)
application.register("canvas", CanvasController)
application.register("chat", ChatController)
eagerLoadControllersFrom("controllers", application)
