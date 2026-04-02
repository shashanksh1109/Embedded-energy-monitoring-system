package com.energy.websocket;

import com.energy.dto.*;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;

@Component
public class LiveDataPublisher {

    @Autowired(required = false)
    private SimpMessagingTemplate messagingTemplate;

    private void send(String topic, Object payload) {
        if (messagingTemplate != null) {
            messagingTemplate.convertAndSend(topic, payload);
        }
    }

    public void publishTemperature(TemperatureResponse reading) {
        send("/topic/temperature/" + reading.getZoneName(), reading);
    }

    public void publishOccupancy(OccupancyResponse reading) {
        send("/topic/occupancy/" + reading.getZoneName(), reading);
    }

    public void publishHvacState(HvacStateResponse state) {
        send("/topic/hvac/" + state.getZoneName(), state);
    }

    public void publishPower(PowerReadingResponse reading) {
        send("/topic/power/" + reading.getZoneName(), reading);
    }

    public void publishAlert(String zoneName, Object payload) {
        send("/topic/alerts/" + zoneName, payload);
    }

}
