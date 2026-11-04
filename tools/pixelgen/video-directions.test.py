"""Cycle candidate selection must preserve source frame order and reject no motion."""
from pathlib import Path
import importlib.util
import math
import unittest
from PIL import Image,ImageDraw

spec=importlib.util.spec_from_file_location('directions',Path(__file__).parent/'examples/pack-kael-video-directions.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)

class DirectionCycleTests(unittest.TestCase):
 def test_full_period_and_source_timestamps(self):
  features=[]
  for i in range(124):
   im=Image.new('RGB',(36,32));d=ImageDraw.Draw(im)
   x=18+round(10*math.sin(i*2*math.pi/28));y=14+round(8*math.cos(i*2*math.pi/28))
   d.rectangle((x-2,y-3,x+2,y+3),fill=(70,170,230));features.append(im)
  result=module.candidate_cycle(features)
  self.assertEqual(result['endFrame']-result['startFrame'],28)
  self.assertEqual(len(set(result['frames'])),8)
  self.assertEqual(result['frames'],sorted(result['frames']))
  self.assertEqual(result['timestamps'],[f/24 for f in result['frames']])
  self.assertLess(result['frames'][-1],result['endFrame'])
 def test_static_video_is_not_accepted_as_a_walk(self):
  with self.assertRaisesRegex(ValueError,'movimento suficiente'):
   module.candidate_cycle([Image.new('RGB',(36,32),'navy') for _ in range(124)])
 def test_bad_background_or_cropped_subject_is_detected(self):
  clear=Image.new('RGBA',(512,512));ImageDraw.Draw(clear).rectangle((180,60,310,460),fill='navy')
  self.assertEqual(module.border_foreground(clear),0)
  dirty=clear.copy();ImageDraw.Draw(dirty).rectangle((0,300,511,511),fill='yellow')
  self.assertGreater(module.border_foreground(dirty),.005)
  with self.assertRaisesRegex(ValueError,'movimento suficiente'):
   module.candidate_cycle([Image.new('RGB',(36,32),'navy') for _ in range(124)],[False]*124)

if __name__=='__main__':unittest.main()
