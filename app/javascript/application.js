// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "controllers"
import "library/turbo_show"
import LocalTime from "local-time"
import "@hotwired/turbo";
import { start } from "@anycable/turbo-stream";
import cable from "cable";

start(cable, { requestSocketIDHeader: true })

LocalTime.start()
//document.addEventListener("turbo:load", () => LocalTime.run())
//document.addEventListener("turbo:frame-load", () => LocalTime.run())
document.addEventListener("turbo:morph", () => LocalTime.run())
