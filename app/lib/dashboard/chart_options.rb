module Dashboard
  module ChartOptions
    module_function

    def donut(labels:, series:, semantic_colors:, total_label: nil, no_data_text: nil)
      {
        chart: {type: "donut"},
        labels: labels,
        series: series,
        _semanticColors: semantic_colors,
        legend: {position: "bottom"},
        plotOptions: {pie: {donut: donut_inner(total_label)}},
        dataLabels: {enabled: false},
        stroke: {width: 2},
        noData: {text: no_data_text || I18n.t("adminit.dashboard_widgets.chart.no_data")}
      }.tap do |opts|
        opts[:_totalFormatter] = "sum" if total_label
      end
    end

    def bar(categories:, series:, semantic_colors:, no_data_text: nil)
      {
        chart: {type: "bar"},
        xaxis: {categories: categories},
        series: series,
        _semanticColors: semantic_colors,
        legend: {show: false},
        dataLabels: {enabled: false},
        stroke: {width: 0},
        noData: {text: no_data_text || I18n.t("adminit.dashboard_widgets.chart.no_data")}
      }
    end

    def column(categories:, series:, semantic_colors:, no_data_text: nil, distributed: true)
      {
        chart: {type: "bar"},
        xaxis: {
          categories: categories,
          labels: {style: {fontSize: "11px"}}
        },
        yaxis: {labels: {style: {fontSize: "11px"}}},
        series: series,
        _semanticColors: semantic_colors,
        legend: {show: false},
        dataLabels: {enabled: true, style: {fontSize: "11px", fontWeight: 600}},
        plotOptions: {
          bar: {
            distributed: distributed,
            borderRadius: 6,
            borderRadiusApplication: "end",
            columnWidth: "55%",
            dataLabels: {position: "top"}
          }
        },
        stroke: {width: 0},
        grid: {strokeDashArray: 4, padding: {left: 10, right: 10}},
        tooltip: {y: {formatter: "_integer"}},
        noData: {text: no_data_text || I18n.t("adminit.dashboard_widgets.chart.no_data")}
      }
    end

    def radial_bar_multiple(labels:, series:, semantic_colors:, total_label: nil, total_value: nil, no_data_text: nil)
      {
        chart: {type: "radialBar"},
        labels: labels,
        series: series,
        _semanticColors: semantic_colors,
        plotOptions: {
          radialBar: {
            offsetY: 0,
            hollow: {size: "38%"},
            track: {background: "#e5e7eb", strokeWidth: "100%", margin: 4},
            dataLabels: {
              name: {fontSize: "13px", offsetY: -2},
              value: {fontSize: "16px", fontWeight: 700, offsetY: 4, formatter: "_percent"},
              total: radial_total(total_label, total_value)
            }.compact
          }
        },
        stroke: {lineCap: "round"},
        legend: {
          show: true,
          position: "bottom",
          fontSize: "12px",
          markers: {width: 10, height: 10, radius: 12},
          itemMargin: {horizontal: 6, vertical: 2}
        },
        noData: {text: no_data_text || I18n.t("adminit.dashboard_widgets.chart.no_data")}
      }
    end

    def area(categories:, series:, semantic_colors:, no_data_text: nil)
      {
        chart: {type: "area", height: 350},
        plotOptions: {
          bar: {
            columnWidth: "10%"
          }
        },
        xaxis: {categories: categories},
        series: series,
        _semanticColors: semantic_colors,
        legend: {position: "top"},
        dataLabels: {enabled: false},
        stroke: {width: 2, curve: "smooth"},
        fill: {type: "gradient", gradient: {shadeIntensity: 1, opacityFrom: 0.4, opacityTo: 0.1}},
        noData: {text: no_data_text || I18n.t("adminit.dashboard_widgets.chart.no_data")}
      }
    end

    def radial_total(total_label, total_value = nil)
      return nil unless total_label

      {
        show: true,
        label: total_label,
        fontSize: "12px",
        formatter: total_value ? "_static:#{total_value}" : "_sum"
      }
    end

    def donut_inner(total_label)
      return {size: "60%"} unless total_label
      {
        size: "65%",
        labels: {
          show: true,
          total: {
            show: true,
            label: total_label
          }
        }
      }
    end

    private_class_method :donut_inner, :radial_total
  end
end
