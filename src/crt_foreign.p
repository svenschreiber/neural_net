
// math
exp :: foreign (x: f64) -> f64;

// random + time
time :: foreign (timer: *u64) -> u64;
printf :: foreign (cstring, f64);