#include "stm32f10x_conf.h"

ADC_TypeDef* adcs[] = { 0, ADC1, ADC2, ADC3 };

int adc_open(int adc)
{
	ADC_TypeDef* adcp;
	if (adc < 1 || adc >= sizeof(adcs)/sizeof(adcs[0]))
		return 0;
	RCC_ADCCLKConfig(RCC_PCLK2_Div4);

	uint32_t periph[4] = {
		0, 
		RCC_APB2Periph_ADC1,
		RCC_APB2Periph_ADC2,
		RCC_APB2Periph_ADC3,
	};

	RCC_APB2PeriphClockCmd(periph[adc], ENABLE);

	adcp = adcs[adc];

	ADC_InitTypeDef init =  {
		.ADC_Mode = ADC_Mode_Independent,
		.ADC_ScanConvMode = DISABLE,
		.ADC_ContinuousConvMode = DISABLE,
		.ADC_ExternalTrigConv = ADC_ExternalTrigConv_None,
		.ADC_DataAlign = ADC_DataAlign_Right,
		.ADC_NbrOfChannel = 1
	};

	ADC_Init(adcp, &init);

	ADC_Cmd(adcp, ENABLE);

	ADC_ResetCalibration(adcp);
	while (ADC_GetCalibrationStatus(adcp) != RESET) {
	}

	ADC_StartCalibration(adcp);
	while (ADC_GetCalibrationStatus(adcp) != RESET) {
	}


	return (int)adcp;
}

void adc_start(int adcp, int channel, int time)
{
	ADC_RegularChannelConfig((ADC_TypeDef*)adcp, channel, 1, time);

	ADC_SoftwareStartConvCmd((ADC_TypeDef*)adcp, ENABLE);
}

int adc_done(int adcp)
{
	return ADC_GetFlagStatus((ADC_TypeDef*)adcp, ADC_FLAG_EOC) == SET ? -1 : 0;
}

int adc_read(int adcp)
{
	return ADC_GetConversionValue((ADC_TypeDef*)adcp);
}
