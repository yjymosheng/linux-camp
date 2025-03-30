#!/bin/bash

mkdir -p ../reports ../data


yesterday=$(date -d "yesterday" "+%Y-%m-%d")
nowaday=$(date "+%Y-%m-%d")

config_file=../config.txt
output_file=../reports/daily_report_$nowaday.txt
all_checks_file=../data/all_checks.log

touch "$output_file"
echo "网站监控日报告: $nowaday" > "$output_file"
echo "=================================" >>"$output_file"

mapfile -t web_name < <(grep -v ^# $config_file | awk '{print $1}')

for i in "${web_name[@]}"; do
    warnning_file=../logs/$i/alerts.log
    echo -e "$i\n\t网站可用性摘要:" >>"$output_file"

    tmp=$(grep "$i" $all_checks_file | grep "$yesterday")
    if [[ -z $tmp ]]; then
        echo "没有昨天的数据" >&2
        rm "$output_file"
        exit 1
    fi

    count_code_times=$(grep "$i" $all_checks_file | grep "$yesterday" | awk '{count[$4]++;time_sum[$4]+=$5} END {for (code in count) print code, count[code], time_sum[code]/count[code]}')
    mapfile -t code < <(echo "$count_code_times" | awk '{print $1}')
    mapfile -t time < <(echo "$count_code_times" | awk '{print $2}')
    mapfile -t average < <(echo "$count_code_times" | awk '{print $3}')

    for j in "${!code[@]}"; do
        echo -e "\t\t${code[$j]} 状态码: ${time[$j]} 次" >>"$output_file"
    done

    echo >>"$output_file"
    echo -e "\t响应时间统计 (秒):" >>"$output_file"
    for j in "${!code[@]}"; do
        echo -e "\t\t${code[$j]} 平均: ${average[$j]}" >>"$output_file"
    done

    echo >>"$output_file"
    date_for_warning=$(grep "$yesterday" "$warnning_file" | awk '{print $3}')
    #假设没有异常的情况下 
    if [[ -s "$date_for_warning" ]]; then
        mapfile -t warning_code < <(echo "$date_for_warning" | awk '{print $1}')
        echo -e "\t异常情况:" >>"$output_file"
        for j in "${!code[@]}"; do
            echo -e "\t\t警告: $i 返回状态码 ${warning_code[$j]}" >>"$output_file"
        done
    else
        echo -e "\t异常情况: " >> "$output_file"
        echo -e "\t\t无"  >> "$output_file"
    fi
done
