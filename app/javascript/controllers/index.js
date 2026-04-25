// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import TimerController from "controllers/timer_controller"
import CanvasController from "controllers/canvas_controller"
application.register("timer", TimerController)
application.register("canvas", CanvasController)
eagerLoadControllersFrom("controllers", application)
