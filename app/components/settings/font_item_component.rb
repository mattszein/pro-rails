class Settings::FontItemComponent < ApplicationViewComponent
  option :font
  option :selected, default: false

  CATEGORY_COLORS = {
    modern: " group-hover:bg-blue-600/50 group-[.selected]:bg-blue-500/20 group-[.selected]:ring-blue-500 ",
    editorial: " group-hover:bg-stone-600/50 group-[.selected]:bg-stone-500/20 group-[.selected]:ring-stone-500 ",
    cosmic: " group-hover:bg-indigo-600/50 group-[.selected]:bg-indigo-500/20 group-[.selected]:ring-indigo-500 ",
    vivid: " group-hover:bg-rose-600/50 group-[.selected]:bg-rose-500/20 group-[.selected]:ring-rose-500 ",
    elegant: " group-hover:bg-amber-600/50 group-[.selected]:bg-amber-500/20 group-[.selected]:ring-amber-500 ",
    code: " group-hover:bg-emerald-600/50 group-[.selected]:bg-emerald-500/20 group-[.selected]:ring-emerald-500 ",
    cyberpunk: " group-hover:bg-purple-600/50 group-[.selected]:bg-purple-500/20 group-[.selected]:ring-purple-500 ",
    anime: " group-hover:bg-cyan-600/50 group-[.selected]:bg-cyan-500/20 group-[.selected]:ring-cyan-500 "
  }

  def font_id
    @font.id
  end
end
