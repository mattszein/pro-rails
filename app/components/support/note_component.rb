module Support
  class NoteComponent < ApplicationViewComponent
    option :note

    def note_classes
      if note.system?
        "bg-slate-100 dark:bg-slate-800/50 border-l-4 border-slate-400"
      else
        "bg-indigo-50 dark:bg-indigo-900/20 border-l-4 border-indigo-400"
      end
    end

    def label_classes
      if note.system?
        "text-slate-500"
      else
        "text-indigo-600 dark:text-indigo-400"
      end
    end
  end
end
