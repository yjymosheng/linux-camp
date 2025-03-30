#!/bin/bash



# 清理一下每次的log嘛 ,突然发现似乎没有必要, 每次往里面添加就行了
# rm -rf ../logs
mkdir -p ../logs

config_file=../config.txt
tmp_url_file=tmp_url_file
all_checks_file=../data/all_checks.log
#导出作为数组
mapfile -t web_name < <(grep -v ^# $config_file | awk '{print $1}')
mapfile -t urls < <(grep -v ^# $config_file | awk '{print $2}')

#初始所用,但是故意进行测试发现这个没用,遂废弃
# if [[ ${#web_name[@]} -ne ${#urls[@]} ]] ; then
# echo "$config_file 格式错误"
# exit 1;
# fi
#添加一个检测
for i in "${!web_name[@]}"; do
    if [[ -z "${web_name[$i]}" || -z "${urls[$i]}" ]]; then
        echo "Error: line $((i + 1)) in $config_file is invalid."
        exit 1
    fi
done

# 开始迭代
for i in "${!web_name[@]}"; do
    response=$(curl -L -s -w "%{http_code} %{time_total}" -o "$tmp_url_file" "${urls[$i]}")
    # echo "$response"
    code=$(echo "$response" | awk '{print $1}' )
    time=$(echo "$response" | awk '{print $2}' )
    date=$(date "+%Y-%m-%d %H:%M:%S")
    md5_value=$(md5sum $tmp_url_file | awk '{print $1}')

    mkdir -p ../logs/"${web_name[$i]}"
    status_file="../logs/${web_name[$i]}/status.log"
    alert_file="../logs/${web_name[$i]}/alerts.log"

    touch "$status_file" "$alert_file"

    #文档的意思似乎是需要都添加到all_checks.log
    echo "$date ${web_name[$i]} $code $time" >> $all_checks_file

    # 把返回code当作数字直接比较吧
    if [[ $code -lt 200 || ($code -ge 400) ]]; then
        echo "警告: ${web_name[$i]} $code $date" >> "$alert_file"
    else
        echo "$date $code $time $md5_value" >> "$status_file"
    fi

done
# http_file=$(curl -L "$urls" > "tmp_file")

rm "$tmp_url_file"