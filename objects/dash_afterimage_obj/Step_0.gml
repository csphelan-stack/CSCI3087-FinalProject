if(hold > 0){

	hold -= 1;
	exit;

}

image_alpha -= start_alpha / fade_time;
if(image_alpha <= 0){
	instance_destroy();
}
