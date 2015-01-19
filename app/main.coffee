clock = new THREE.Clock()
clock.start()

Audio = require("Audio")
audio = new Audio()

Backdrop = require("backdrop/Backdrop")
backdrop = new Backdrop()

resize = () ->
  backdrop.width = window.innerWidth
  backdrop.height = window.innerHeight
  backdrop.resize()

window.addEventListener("resize",resize)
resize()

window.freqStops = [0,0.02,0.5,0.7,1]
#The normalized time
time = 0

renderloop = () ->
  if window.requestAnimationFrame?
    window.requestAnimationFrame(renderloop)
  else
    setTimeout(renderloop,1000/60)

  delta = Math.min(clock.getDelta(),0.1)

  #Fade in logo if it's time
  if (time<2) and (delta+time>=2)
    document.getElementById("splash").style.opacity = 1
    #quotes.run()

  #Check the width and height sometimes to detect resize (a workaround)
  if (time % 1) > (time + delta) % 1
    if (backdrop.width isnt window.innerWidth)
      resize()

  #Update time
  time += delta

  #Analyze audio to get that backdrop dancing
  audio.analyse()
  for i in [0..backdrop.audioData.length-1]
    backdrop.audioData[i] = 2*audio.getFrequency(freqStops[i], freqStops[i+1])/127

  #Sync variables
  backdrop.time = time
  backdrop.currentScroll = 0
  if audio.avg == 0
    backdrop.concavity = 0.99*backdrop.concavity+0.01
  else
    backdrop.concavity = 0.8*backdrop.concavity

  backdrop.render()


renderloop()
resize()
