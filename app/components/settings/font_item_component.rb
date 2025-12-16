class Settings::FontItemComponent < ApplicationViewComponent
  option :font
  option :selected, default: false

  CATEGORY_COLORS = {
    modern: " group-hover:bg-blue-600/50 group-[.selected]:bg-blue-500/20 group-[.selected]:ring-blue-500 ",
    serene: " group-hover:bg-teal-600/50 group-[.selected]:bg-teal-500/20 group-[.selected]:ring-teal-500 ",
    cosmic: " group-hover:bg-indigo-600/50 group-[.selected]:bg-indigo-500/20 group-[.selected]:ring-indigo-500 ",
    vivid: " group-hover:bg-rose-600/50 group-[.selected]:bg-rose-500/20 group-[.selected]:ring-rose-500 ",
    warm: " group-hover:bg-orange-600/50 group-[.selected]:bg-orange-500/20 group-[.selected]:ring-orange-500 ",
    code: " group-hover:bg-emerald-600/50 group-[.selected]:bg-emerald-500/20 group-[.selected]:ring-emerald-500 ",
    cyberpunk: " group-hover:bg-purple-600/50 group-[.selected]:bg-purple-500/20 group-[.selected]:ring-purple-500 ",
    minimal: " group-hover:bg-slate-600/50 group-[.selected]:bg-slate-500/20 group-[.selected]:ring-slate-500 "
  }

  def font_id
    @font.id
  end
end
