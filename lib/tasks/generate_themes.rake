namespace :themes do
  desc "Generate Tailwind CSS theme files"
  task generate: :environment do
    def generate_scale(name, hue, chroma)
      css = []
      
      hue_adjustment = case hue
      when 60..120 then 0.05
      when 180..240 then -0.03
      else 0
      end

      {
        50 => 0.99,
        100 => 0.96,
        200 => 0.90,
        300 => 0.82,
        400 => 0.72,
        500 => 0.62,
        600 => 0.52,
        700 => 0.42,
        800 => 0.32,
        900 => 0.22,
        950 => 0.16
      }.each do |shade, base_lightness|
        lightness = if [50, 950].include?(shade)
          base_lightness
        else
          base_lightness + hue_adjustment
        end

        adjusted_chroma = case shade
        when 50 then chroma * 0.1
        when 100 then chroma * 0.2
        when 950 then chroma * 0.4
        when 900 then chroma * 0.6
        else chroma
        end

        safe_lightness = lightness.round(4)
        safe_chroma = adjusted_chroma.round(4)

        css << "    --color-#{name}-#{shade}: oklch(#{safe_lightness} #{safe_chroma} #{hue});"
      end
      
      css.join("\n")
    end

    def create_theme_file(theme_name, primary_hue, primary_chroma, secondary_hue, secondary_chroma, category)
      path = Rails.root.join("app/assets/tailwind/themes/#{theme_name}.css")

      content = <<~CSS
        /* Category: #{category} */
        @layer utilities {
          .theme-#{theme_name} {
            /* PRIMARY (Hue: #{primary_hue}, Chroma: #{primary_chroma}) */
        #{generate_scale("primary", primary_hue, primary_chroma)}
            /* SECONDARY (Hue: #{secondary_hue}, Chroma: #{secondary_chroma}) */
        #{generate_scale("secondary", secondary_hue, secondary_chroma)}
        
            /* SEMANTIC TEXT MAPPING */
            --color-text-heading-strong: var(--color-primary-900);
            --color-text-heading-soft:   var(--color-primary-800);
            --color-text-body-strong:    var(--color-primary-700);
            --color-text-body:           theme(colors.slate.600);
            &:where(.dark, .dark *) {
              --color-text-heading-strong: var(--color-primary-200);
              --color-text-heading-soft:   var(--color-primary-100);
              --color-text-body-strong:    var(--color-primary-100);
              --color-text-body:           theme(colors.slate.100);
            }
          }
        }
      CSS
      File.write(path, content)
      Rails.logger.debug { "✅ Created themes/#{theme_name}.css (#{category})" }
    end

    # --- THEME DEFINITIONS ---
    # Format: [Name, Pri Hue, Pri Chroma, Sec Hue, Sec Chroma, Category]
    themes = [
      # ═══════════════════════════════════════
      # TECH EDGE - Sharp, modern, digital (8)
      # ═══════════════════════════════════════
      ["hyper", 290, 0.22, 220, 0.18, "Tech Edge"],  # Purple / Cyan
      ["aurora", 250, 0.18, 25, 0.22, "Tech Edge"],  # Azure / Coral
      ["eclipse", 270, 0.15, 150, 0.20, "Tech Edge"],  # Indigo / Mint
      ["galaxy", 300, 0.20, 340, 0.18, "Tech Edge"],  # Violet / Pink
      ["synth", 330, 0.24, 285, 0.18, "Tech Edge"],  # Magenta / Purple
      ["thunder", 255, 0.16, 65, 0.20, "Tech Edge"],  # Storm Blue / Electric Yellow
      ["matrix", 155, 0.22, 200, 0.18, "Tech Edge"],  # Bright Green / Aqua-cyan
      ["cyber", 210, 0.20, 320, 0.20, "Tech Edge"],  # Cyan Blue / Neon Pink

      # ═══════════════════════════════════════
      # SERENE - Calm, natural, balanced (8)
      # ═══════════════════════════════════════
      ["botanic", 160, 0.08, 35, 0.14, "Serene"],     # Sage / Clay-orange
      ["reef", 190, 0.16, 70, 0.20, "Serene"],     # Teal / Tangerine
      ["oceanic", 215, 0.18, 190, 0.12, "Serene"],     # Deep blue / Teal
      ["forest", 150, 0.18, 125, 0.14, "Serene"],     # Rich emerald / Yellow-green
      ["dune", 110, 0.10, 45, 0.16, "Serene"],     # Muted Olive / Warm Sand
      ["mauve", 310, 0.12, 0, 0.00, "Serene"],     # Soft lavender-mauve / Charcoal
      ["glacier", 195, 0.10, 230, 0.10, "Serene"],     # Teal-cyan / Cool blue
      ["lavender", 310, 0.14, 270, 0.10, "Serene"],     # Lavender / Soft Indigo

      # ═══════════════════════════════════════
      # COSMIC - Futuristic, space-inspired (8)
      # ═══════════════════════════════════════
      ["nebula", 280, 0.18, 180, 0.20, "Cosmic"],     # Deep Purple / Cyan
      ["starlight", 240, 0.16, 55, 0.18, "Cosmic"],     # Cool Blue / Amber
      ["void", 265, 0.12, 265, 0.22, "Cosmic"],     # Deep Indigo / Bright Indigo
      ["pulsar", 310, 0.20, 195, 0.18, "Cosmic"],     #  Magenta / Bright Cyan
      ["vapor", 250, 0.08, 340, 0.18, "Cosmic"],     # Soft blue / Pink (less overlap)
      ["prism", 270, 0.20, 120, 0.20, "Cosmic"],     # Purple / Green spectrum
      ["comet", 45, 0.22, 220, 0.18, "Cosmic"],     # Fiery orange / Blue streak (inverted)
      ["royal", 275, 0.18, 80, 0.18, "Cosmic"],      # Grape / Gold

      # ═══════════════════════════════════════
      # VIVID - High energy, bold, vibrant (8)
      # ═══════════════════════════════════════
      ["sunset", 280, 0.18, 45, 0.24, "Vivid"],      # Violet / Orange
      ["berry", 350, 0.20, 140, 0.22, "Vivid"],      # Raspberry / Acid Green
      ["flamingo", 350, 0.22, 290, 0.18, "Vivid"],      # Hot Pink / Purple
      ["solar", 75, 0.20, 250, 0.12, "Vivid"],     # Golden sun / Deep space blue
      ["coral", 12, 0.24, 340, 0.18, "Vivid"],      # VIVID coral-red / Hot pink
      ["neon", 165, 0.24, 340, 0.24, "Vivid"],      # Electric Green / Hot Pink
      ["phoenix", 25, 0.24, 60, 0.22, "Vivid"],      # Scarlet / Yellow
      ["bloom", 340, 0.22, 115, 0.20, "Vivid"],      # Hot pink / Lime yellow

      # ═══════════════════════════════════════
      # NIGHT OWL - Blue-free, warm, eye-friendly (8)
      # ═══════════════════════════════════════
      ["amber", 40, 0.16, 30, 0.12, "Night Owl"],  # Warm amber / Burnt orange
      ["candle", 20, 0.12, 55, 0.20, "Night Owl"],  # Warm red glow / BRIGHT Golden flame
      ["ember", 35, 0.22, 355, 0.20, "Night Owl"],  # Bright orange / Deep red
      ["hearth", 20, 0.14, 350, 0.16, "Night Owl"],  # Terracotta / Pink-red
      ["vintage", 80, 0.10, 0, 0.00, "Night Owl"],  # Muted gold / Charcoal
      ["sepia", 50, 0.08, 110, 0.08, "Night Owl"],  # Brown / Olive
      ["autumn", 45, 0.18, 140, 0.14, "Night Owl"],  # Rust / Forest green
      ["twilight", 340, 0.14, 40, 0.14, "Night Owl"]  # Rosy dusk / Warm amber
    ]

    # 3. Run the execution logic
    themes.each { |t| create_theme_file(*t) }

    Rails.logger.debug "\n📊 SUMMARY:"
    Rails.logger.debug "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    categories = themes.group_by { |t| t[5] }
    categories.each do |cat, themes_list|
      Rails.logger.debug { "\n#{cat.upcase} (#{themes_list.length}):" }
      Rails.logger.debug { "  #{themes_list.map(&:first).join(", ")}" }
    end
    Rails.logger.debug { "\n🎨 Total themes: #{themes.length}" }
    Rails.logger.debug "✨ Each theme now has more distinct personality!"
  end
end
